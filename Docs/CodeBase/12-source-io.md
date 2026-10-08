# Source IO (Git Refs)

← [Plugin](11-plugin.md) | [Index →](README.md)

---

## Overview

When `Configuration.sourceRef` is set, the IO module reads file content from a git ref instead of the working tree. The pipeline never knows the difference — it sees a `SourceFileLister` and a `SourceReader` regardless of where the bytes originate. See [File Discovery & Source IO](02-file-discovery.md) for the protocol-level overview; this chapter documents the git-backed implementations.

```mermaid
flowchart TD
    cfg["Configuration.sourceRef"] --> RES["GitRefResolver"]
    RES --> ROOT["repositoryRoot + resolvedSha"]
    ROOT --> LIS["GitRefSourceFileLister"]
    ROOT --> RDR["GitRefSourceReader"]
    LIS -->|"git ls-tree -r &lt;sha&gt;<br/>or git ls-files --stage"| GIT["git (subprocess via GitProcessRunner)"]
    RDR -->|"git cat-file blob &lt;sha&gt;:&lt;path&gt;"| GIT
```

The git layer is composed of eight types and one free function, each in its own file:

| Type | Responsibility |
|---|---|
| `SourceRefError` | Tagged errors raised across the IO layer |
| `GitProcessRunner` | Spawns `git` as a subprocess and returns its output |
| `GitProcessRunner.ProcessOutput` | stdout + stderr + exitCode triple |
| `GitRefResolver` | Resolves a user-provided ref into repo root + sha |
| `GitRefResolver.Resolved` | Output of `resolve(ref:in:)` |
| `GitRefSourceFileLister` | Lists files under `paths:` from a ref's tree |
| `GitRefSourceFileLister.TreeEntry` | One line of `git ls-tree`/`ls-files` output |
| `GitRefSourceReader` | Reads a single blob from a ref |
| `repositoryRelativePath(for:in:)` | Free function — normalizes any path to repo-root-relative |

---

## SourceRefError

```swift
enum SourceRefError: Error, Equatable, Sendable
```

| Case | Trigger |
|---|---|
| `.gitExecutableNotFound` | `git` is missing from `PATH` (`env` exits with 127), or the process cannot be spawned at all (e.g. the working directory does not exist) |
| `.notARepository(workingDirectory:)` | `git rev-parse --show-toplevel` exits non-zero — caller is not inside a repo |
| `.unknownRef(ref:)` | `git rev-parse --verify --quiet <ref>` exits non-zero |
| `.gitCommandFailed(command:, exitCode:, stderr:)` | The listing (`ls-tree` / `ls-files`) or `cat-file` command exited non-zero. `command` is a human-readable description such as `git ls-tree -r <sha> -- <path>` or `git cat-file blob <sha>:<path>` |

---

## GitProcessRunner

```swift
struct GitProcessRunner: Sendable
init(environment: [String: String]? = nil)
```

Thin wrapper over `Foundation.Process`. The optional `environment` overrides the process environment — primarily used in tests to set `PATH=""` and verify the `gitExecutableNotFound` path.

```swift
func run(args: [String], workingDirectory: String) throws -> ProcessOutput
```

- Executes `/usr/bin/env git <args...>` from the given working directory.
- If `Process.run()` itself throws (including when `workingDirectory` does not exist) → `SourceRefError.gitExecutableNotFound`.
- If exit code is `127` (env-couldn't-find-git) → `SourceRefError.gitExecutableNotFound`.
- Otherwise returns the captured stdout, stderr (decoded as UTF-8, empty if undecodable), and exit code. A non-zero exit code is **not** an error at this level — callers decide how to map it.

```swift
struct GitProcessRunner.ProcessOutput: Sendable
let stdout:   Data
let stderr:   String
let exitCode: Int32
```

---

## GitRefResolver

```swift
struct GitRefResolver: Sendable
init(runner: GitProcessRunner = .init())
func resolve(ref: String, in workingDirectory: String) throws -> Resolved
```

Resolves a user-provided ref to a stable identifier:

1. `git rev-parse --show-toplevel` from the working directory → repository root.
   - Fails with `notARepository(workingDirectory:)` on a non-zero exit.
2. If `ref == ":0"` → returns the literal `:0` as the resolved sha (the index has no single sha).
3. Otherwise `git rev-parse --verify --quiet <ref>`, run from the repository root → the full object name (trimmed stdout).
   - Fails with `unknownRef(ref:)` on a non-zero exit.

```swift
struct GitRefResolver.Resolved: Equatable, Sendable
let repositoryRoot: String
let resolvedSha:    String
```

The resolved sha is what gets used downstream both as the git object spec (for `cat-file`/`ls-tree`) and as the cache namespace key. Mutable refs like `HEAD` or `main` are resolved once at the start of the run — moving the ref between subsequent runs cleanly misses the cache without contaminating prior entries.

---

## GitRefSourceFileLister

```swift
struct GitRefSourceFileLister: SourceFileLister
init(
    ref: String,
    resolvedSha: String,
    repositoryRoot: String,
    crossLanguageEnabled: Bool,
    excludePatterns: [String] = [],
    runner: GitProcessRunner = .init(),
    stderr: @escaping @Sendable (String) -> Void = { FileHandle.standardError.write(Data($0.utf8)) }
)
func listFiles(in paths: [String]) throws -> [String]
```

For each input path:

1. Convert to repo-relative via `repositoryRelativePath(for:in:)`. Out-of-repo paths throw `FileDiscoveryError.pathOutsideRepository`.
2. Run the listing command from the repository root:
   - Named ref / sha: `git ls-tree -r <resolvedSha> -- <relativePath>`
   - Index (`resolvedSha == ":0"`): `git ls-files --stage -- <relativePath>`
   - When the input path is the repository root itself (empty relative path), the `-- <relativePath>` scope is omitted.
   - Non-zero exit → `SourceRefError.gitCommandFailed(...)`.
3. No entries → `FileDiscoveryError.pathDoesNotExistInRef(path:, ref:)` (with the original input path and the user-provided ref).
4. Parse each line into a `TreeEntry` (lines without a tab are ignored), skip submodules (mode `160000`) with the warning `swift-cpd: skipping submodule '<path>' at <ref>` sent to the injected `stderr` closure, keep only `.swift` files (plus `.m`, `.mm`, `.h`, `.c`, `.cpp` when `crossLanguageEnabled`), and drop files whose absolute path (`repositoryRoot + "/" + path`) matches `excludePatterns` via `GlobMatcher`.
5. Return the absolute paths de-duplicated and sorted.

Exclusion is evaluated against **file paths only** (there is no directory enumeration to prune). A pattern that names a directory without a trailing slash, such as `Sources/Generated`, therefore excludes nothing in git mode; use `Sources/Generated/` or `Sources/Generated/**` instead. See [GlobMatcher](02-file-discovery.md#globmatcher).

```swift
func parseEntry(_ line: Substring) -> TreeEntry?
```

Internal (not `private`) so tests can exercise it directly. Splits the line at the first tab: the path is everything after it, the mode is the first space-separated field before it. Returns `nil` if there is no tab or no mode.

```swift
struct GitRefSourceFileLister.TreeEntry: Equatable, Sendable
static let submoduleMode = "160000"
let mode: String
let path: String
var isSubmodule: Bool { mode == Self.submoduleMode }
```

---

## GitRefSourceReader

```swift
struct GitRefSourceReader: SourceReader
init(ref: String, resolvedSha: String, repositoryRoot: String, runner: GitProcessRunner = .init())
func read(file: String) throws -> Data
```

1. Convert `file` to repo-relative via `repositoryRelativePath(for:in:)`.
2. Run `git cat-file blob <resolvedSha>:<relativePath>` from the repository root (with the index, the spec becomes `:0:<relativePath>`).
3. Non-zero exit → `SourceRefError.gitCommandFailed(...)` with the git stderr verbatim — typically because the file does not exist at the ref.

The reader returns raw bytes without assuming UTF-8; the `AnalysisPipeline` decodes when it needs a `String`.

---

## repositoryRelativePath(for:in:)

```swift
func repositoryRelativePath(for input: String, in repositoryRoot: String) throws -> String
```

Free function shared by the reader and the lister. Behavior:

- An absolute `input` is used as-is; a relative `input` is resolved against `repositoryRoot` (not the current working directory).
- Both sides of the comparison are standardized via `NSString.standardizingPath` — this is needed on macOS where `/private/var/...` and `/var/...` refer to the same directory but differ as strings.
- If `input` resolves to `repositoryRoot` itself, returns `""`.
- If `input` resolves under `repositoryRoot`, returns the repo-relative substring.
- Otherwise throws `FileDiscoveryError.pathOutsideRepository(path:, repositoryRoot:)`.

This single helper eliminates a Type-2 clone that previously existed between the two consumers.

---

## Source IO at the entry point

`SwiftCPD.runAnalysis` chooses the IO pair based on `Configuration.sourceRef`:

```swift
private static func buildSourceIO(
    configuration: Configuration
) throws -> (lister: any SourceFileLister, reader: any SourceReader, resolvedSha: String?)
```

- `sourceRef == nil` → `(FilesystemSourceFileLister, WorkingTreeSourceReader, nil)`
- otherwise → `GitRefResolver().resolve(ref:in:)` with the current working directory, then `(GitRefSourceFileLister, GitRefSourceReader, resolvedSha)`. Both receive the user-provided `sourceRef` as `ref` (used in messages and errors) and the resolved sha for git commands.

The `resolvedSha` returned alongside the IO pair is threaded into `AnalysisPipeline.SourceOptions.resolvedSha`, which the pipeline uses when constructing `CacheKey` for each file. See [Pipeline](04-pipeline.md) and [Cache & Baseline](10-cache-baseline.md).

---

← [Plugin](11-plugin.md) | [Index →](README.md)
