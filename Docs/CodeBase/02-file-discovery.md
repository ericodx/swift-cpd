# File Discovery & Source IO

← [CLI & Configuration](01-cli-configuration.md) | Next: [Tokenization →](03-tokenization.md)

---

## Overview

Source files reach the analysis pipeline through two cooperating abstractions:

- **`SourceFileLister`** — lists the paths to analyze under the configured `paths:` entries.
- **`SourceReader`** — reads the raw bytes of a single file.

Each has two implementations, paired by mode:

| Mode | Lister | Reader |
|---|---|---|
| Working tree (default) | `FilesystemSourceFileLister` (wraps `SourceFileDiscovery`) | `WorkingTreeSourceReader` |
| Git ref (`--source-ref`) | `GitRefSourceFileLister` | `GitRefSourceReader` |

`SwiftCPD.runAnalysis` picks the pair from `Configuration.sourceRef` and feeds the listed files to `AnalysisPipeline` together with the reader. The pipeline never touches the filesystem directly.

```mermaid
flowchart TD
    cfg[Configuration] --> sel{sourceRef set?}
    sel -- no --> FS["FilesystemSourceFileLister<br/>+ WorkingTreeSourceReader"]
    sel -- yes --> GR["GitRefResolver →<br/>GitRefSourceFileLister<br/>+ GitRefSourceReader"]
    FS --> files["[String] file paths"]
    GR --> files
    files --> PIPE[AnalysisPipeline]
    FS -.reads working tree.-> WT[Filesystem]
    GR -.reads blobs via git cat-file.-> GIT["git (subprocess)"]
```

---

## Protocols

### SourceFileLister

```swift
protocol SourceFileLister: Sendable
func listFiles(in paths: [String]) throws -> [String]
```

Returns absolute paths sorted deterministically. Relative input paths are resolved against the current working directory by the filesystem lister and against the repository root by the git lister.

### SourceReader

```swift
protocol SourceReader: Sendable
func read(file: String) throws -> Data
```

Returns raw bytes. The reader does not assume UTF-8; the pipeline decodes when needed.

---

## Working-tree implementations

### FilesystemSourceFileLister

```swift
struct FilesystemSourceFileLister: SourceFileLister
init(crossLanguageEnabled: Bool, excludePatterns: [String] = [])
```

Thin wrapper around `SourceFileDiscovery` so the pipeline depends on the `SourceFileLister` protocol instead of a concrete struct.

### WorkingTreeSourceReader

```swift
struct WorkingTreeSourceReader: SourceReader
```

Reads file content via `Data(contentsOf: URL(fileURLWithPath:))`. No state.

---

## Git-ref implementations

When `Configuration.sourceRef` is set, the IO module shells out to `git` instead of the filesystem. See [Source IO (Git Refs)](12-source-io.md) for the full reference; this section is a summary.

```swift
struct GitRefSourceFileLister: SourceFileLister
init(
    ref: String,
    resolvedSha: String,
    repositoryRoot: String,
    crossLanguageEnabled: Bool,
    excludePatterns: [String] = [],
    runner: GitProcessRunner = .init(),
    stderr: @escaping @Sendable (String) -> Void = { ... }
)
```

- For named refs/shas: runs `git ls-tree -r <resolvedSha> -- <path>` once per input path.
- For `:0` (the index): runs `git ls-files --stage -- <path>` once per input path.
- Skips submodule entries (mode `160000`) with a warning to stderr.
- Applies the same extension filter and `GlobMatcher` exclusions as the filesystem lister, then returns the de-duplicated, sorted absolute paths.

```swift
struct GitRefSourceReader: SourceReader
init(ref: String, resolvedSha: String, repositoryRoot: String, runner: GitProcessRunner = .init())
```

- Reads via `git cat-file blob <resolvedSha>:<repo-relative-path>` (or `:0:<path>` when the ref is the index).

Both git implementations share a path-normalization helper, `repositoryRelativePath(for:in:)`, that throws `FileDiscoveryError.pathOutsideRepository` when a path escapes the repo root.

---

## SourceFileDiscovery

```mermaid
flowchart TD
    paths["Configuration.paths"] --> SFD["SourceFileDiscovery"]
    SFD --> item{Item type?}
    item -- symlink --> skip[Skip]
    item -- directory --> excl{"Excluded name or\nGlobMatcher.matches?"}
    excl -- yes --> prune["skipDescendants() + Skip"]
    excl -- no --> item
    item -- file --> excl2{"Excluded name or\nGlobMatcher.matches?"}
    excl2 -- yes --> skip
    excl2 -- no --> ext{Extension?}
    ext -- .swift --> result["[String] file paths"]
    ext -- ".m .mm .h .c .cpp" --> CL{crossLanguageEnabled?}
    CL -- yes --> result
    CL -- no --> skip
```

```swift
struct SourceFileDiscovery: Sendable
```

### Initializer

```swift
init(crossLanguageEnabled: Bool, excludePatterns: [String] = [])
```

### Method

```swift
func findSourceFiles(in paths: [String]) throws -> [String]
```

Throws `FileDiscoveryError.pathDoesNotExist(String)` if any path in `paths` does not exist on disk. Relative paths are resolved against `FileManager.default.currentDirectoryPath`.

Each input path is handled according to its type:

- **Directory** — enumerated recursively (see rules below).
- **File** — included if its extension is valid. Exclusion patterns and always-excluded names are **not** applied to a file passed directly as an input path.

### Rules

- **Included extensions:** `.swift` always; `.m`, `.mm`, `.h`, `.c`, `.cpp` when `crossLanguageEnabled` is `true`.
- **Always-excluded names** (any enumerated entry with this last path component is skipped, and a directory is pruned):
  - `.build` · `.git` · `DerivedData` · `Pods` · `Carthage` · `SourcePackages`
- **Hidden entries** (names starting with `.`) and **package contents** (bundle-like directories) are skipped by the enumerator (`.skipsHiddenFiles`, `.skipsPackageDescendants`).
- **Pattern exclusions:** enumerated files and directories whose absolute path matches any entry in `excludePatterns` via `GlobMatcher`. A matching directory is pruned with `skipDescendants()`.
- Exclusions apply only to entries found **during enumeration**: an input directory itself is never tested, so `--exclude Sources/Generated` has no effect when `Sources/Generated` is one of the input paths.
- **Symlinks:** entries that are symbolic links are skipped, never followed.
- The returned array is sorted for deterministic processing order (it is not de-duplicated).

---

## GlobMatcher

```swift
struct GlobMatcher: Sendable
```

Matches file paths against a list of glob patterns. Used to implement the `--exclude` option.

```swift
init(patterns: [String])
func matches(_ filePath: String) -> Bool
```

Each pattern is compiled into a regular expression:

| Glob | Regex | Meaning |
|---|---|---|
| `**/` | `(.+/)?` | Zero or more leading path components |
| `**` (elsewhere) | `.*` | Any characters, including `/` |
| `*` | `[^/]*` | Any characters within a single path component |
| `?` | `[^/]` | Exactly one character other than `/` |
| `.` `(` `)` `+` `^` `$` `\|` `{` `}` | escaped | Matched literally |

Other characters (including `[` and `]`) are passed through to the regex unchanged. A pattern that does not compile into a valid regex (e.g. `[invalid`) is silently dropped. A path is excluded if it matches **any** pattern in the list.

### Matching semantics

- **Basename patterns** (no `/` anywhere in the pattern, e.g. `*.generated.swift`): matched against the last path component only.
- **Absolute patterns** (starting with `/`): matched against the full path anchored at the start.
- **Relative patterns** (containing `/`, not starting with `/`): matched starting at any path-component boundary, and must match through to the **end** of the path. `Sources/Generated.swift` matches `/Users/project/Sources/Generated.swift`; `Sources/Foo/Bar` matches the directory `/Users/project/Sources/Foo/Bar` (which the filesystem walk then prunes) but not the file `/Users/project/Sources/Foo/Bar/File.swift` on its own.
- **Directory patterns** (ending with `/`): the trailing slash is dropped and the pattern matches the directory itself and anything below it. `Sources/Generated/` matches both the directory path and any file inside it, so it works in working-tree mode (early pruning via `enumerator.skipDescendants()`) and in git-ref mode (where only file paths are tested).

### CompiledPattern

```swift
struct CompiledPattern: Sendable
let regex: NSRegularExpression
let basenameOnly: Bool
```

A plain value holding one pattern's pre-compiled `NSRegularExpression` and whether it is matched against the basename only. `GlobMatcher.init(patterns:)` builds one per valid pattern.

---

## FileDiscoveryError

```swift
enum FileDiscoveryError: Error, Sendable
```

| Case | Meaning |
|---|---|
| `.pathDoesNotExist(String)` | A path passed to `findSourceFiles(in:)` does not exist on the filesystem |
| `.pathDoesNotExistInRef(path:, ref:)` | A path has no matches in the listed ref's tree (git mode) |
| `.pathOutsideRepository(path:, repositoryRoot:)` | A path resolves outside the repository root (git mode) |

---

← [CLI & Configuration](01-cli-configuration.md) | Next: [Tokenization →](03-tokenization.md)
