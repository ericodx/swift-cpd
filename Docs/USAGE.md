# Usage & Configuration Guide

This guide covers every way to run and configure `swift-cpd`, from a first run to full CI integration.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Configuration File](#configuration-file)
3. [CLI Reference](#cli-reference)
4. [Reading from a git ref (--source-ref)](#reading-from-a-git-ref---source-ref)
5. [Output Formats](#output-formats)
6. [Baseline Workflow](#baseline-workflow)
7. [Inline Suppression](#inline-suppression)
8. [CI/CD Integration](#cicd-integration)
9. [Xcode & SPM Plugin](#xcode--spm-plugin)
10. [Exit Codes](#exit-codes)

---

## Quick Start

### SPM project

```bash
# Generate a default config file (auto-detects source paths)
swift-cpd init

# Run with the generated config
swift-cpd

# Or pass paths directly without a config file
swift-cpd Sources/
```

### Xcode project

```bash
# Auto-detects your target folder (e.g. MyApp/)
swift-cpd init

# Edit .swift-cpd.yml if needed, then run
swift-cpd
```

### First-time output (text format)

```
Found 2 clone(s) in 47 files (1.30s)

Clone 1 (Type-2, 142 tokens, 18 lines):
  Sources/MyApp/Networking/UserService.swift:45-62
  Sources/MyApp/Networking/ProductService.swift:91-108

Clone 2 (Type-3, 198 tokens, 24 lines):
  Sources/MyApp/ViewModels/ListViewModel.swift:12-35
  Sources/MyApp/ViewModels/DetailViewModel.swift:18-41
```

---

## Configuration File

`swift-cpd` looks for `.swift-cpd.yml` in the current directory by default. If the file is absent, built-in defaults are used. Generate a starter file with:

```bash
swift-cpd init
```

`init` writes `.swift-cpd.yml` in the current directory and refuses to overwrite an existing one (it prints `error: .swift-cpd.yml already exists.` and exits `2`). `paths:` is filled automatically: `Sources/` when that directory exists; otherwise every non-hidden top-level directory that contains `.swift` files (skipping build and dependency folders such as `.build`, `build`, `DerivedData`, `Pods`, `Carthage`, `vendor`, `Packages`); `Sources/` again if nothing is found. The generated file contains:

```yaml
paths:
  - Sources/
minimumTokenCount: 50
minimumLineCount: 5
outputFormat: text
type3Similarity: 70
type4Similarity: 80
exclude: []
ignoreSameFile: true
ignoreStructural: true
enabledCloneTypes:
  - 1
  - 2
  - 3
  - 4
# noCache: true
```

Note that the generated file enables `ignoreSameFile` and `ignoreStructural`, while the built-in defaults for both are `false`.

### Full reference

```yaml
# ── Paths ────────────────────────────────────────────────────────────────────

# Directories to analyze. Accepts multiple entries.
# swift-cpd init fills this automatically based on your project layout.
paths:
  - Sources/
  - Plugins/

# ── Detection thresholds ─────────────────────────────────────────────────────

# Minimum number of tokens a fragment must have to be reported as a clone.
# Lower values find smaller clones but increase noise. Range: 10–500.
minimumTokenCount: 50

# Minimum number of lines a fragment must span. Range: 2–100.
minimumLineCount: 5

# Clone types to detect. Remove entries to skip specific detectors.
# Type 1/2: exact/parameterized (fast). Type 3: near-miss. Type 4: semantic.
# Default when the key is absent: all four types.
enabledCloneTypes:
  - 1
  - 2
  - 3
  - 4

# ── Type 3 (near-miss) tuning ────────────────────────────────────────────────

# Minimum Greedy String Tiling similarity to report a Type 3 clone. Range: 50–100.
type3Similarity: 70

# Minimum matching tile length for GST. Smaller values find more fragmented matches.
# Range: 2–20.
type3TileSize: 5

# Jaccard pre-filter threshold. Pairs below this are skipped before GST runs.
# Lower values increase recall at the cost of speed. Range: 10–80.
type3CandidateThreshold: 30

# ── Type 4 (semantic) tuning ─────────────────────────────────────────────────

# Minimum combined semantic similarity to report a Type 4 clone. Range: 60–100.
type4Similarity: 80

# ── Output ────────────────────────────────────────────────────────────────────

# Output format: text | json | html | xcode
# An unrecognized value silently falls back to text.
outputFormat: text

# ── Filters ──────────────────────────────────────────────────────────────────

# Ignore clones where all fragments are in the same file. Default: false.
ignoreSameFile: true

# Ignore Type 3 and Type 4 (structural/semantic) clones. Default: false.
ignoreStructural: true

# Glob patterns for files to exclude. Patterns without a / match the file or
# directory name only; patterns containing a / are evaluated against the full path.
# Relative patterns match at path-component boundaries anywhere in the absolute path.
# Patterns ending with / exclude that directory and all files within it.
exclude:
  - "**/*Tests*"
  - "**/Generated/**"
  - "**/*.generated.swift"
  - "Sources/MyApp/Discovery/Operators/"

# ── Cache ─────────────────────────────────────────────────────────────────────

# Disable caching of tokenization results.
# When true, files are re-tokenized on every run and no cache is read or written.
# noCache: true

# ── Cross-language ────────────────────────────────────────────────────────────

# Also analyze Objective-C/C files (.m, .mm, .h, .c, .cpp).
crossLanguageEnabled: false

# ── Suppression ───────────────────────────────────────────────────────────────

# Comment tag used to suppress specific regions from analysis.
inlineSuppressionTag: swiftcpd:ignore

# ── CI quality gate ───────────────────────────────────────────────────────────

# Exit with code 1 only if the duplication percentage exceeds this value (0–100).
# Remove this key to disable the quality gate (any clone then exits 1).
maxDuplication: 5.0

# ── Git ref source ────────────────────────────────────────────────────────────

# Read source files from the given git ref instead of the working tree.
# Accepts any ref understood by `git rev-parse`: branch, tag, sha,
# HEAD, HEAD~1, or `:0` for the index (staged blobs).
# Omit or leave empty to read the working tree (default).
# sourceRef: HEAD
```

### Supported YAML syntax

The configuration file is read by a minimal built-in parser, not a full YAML implementation:

- Only top-level `key: value` pairs. Unknown keys are ignored.
- Lists must use block style (`- item` on separate lines); the only inline list accepted is the empty list `[]`. Inline lists such as `[1, 2]` are rejected.
- Values may be wrapped in single or double quotes. Booleans accept `true`/`false`/`yes`/`no` (case-insensitive).
- Comments start with `#` at the beginning of a line or with ` #` (space, then `#`) anywhere after it, including inside quoted values.

A malformed file, or a numeric/boolean key with an invalid value, fails with `error: invalid YAML in configuration file '<path>'` and exit code `2`.

### Precedence

When a value is set in both the CLI and the YAML file, the CLI value wins.

```
CLI argument  >  .swift-cpd.yml  >  built-in default
```

Exceptions to the simple override rule:

- **Paths**: paths given on the CLI replace `paths:` entirely.
- **Exclude patterns**: `--exclude` patterns are *added* to the YAML `exclude:` list, not substituted.
- **Boolean flags** (`--ignore-same-file`, `--ignore-structural`, `--cross-language`, `--no-cache`) can only turn a feature on. When the YAML sets one of them to `true`, there is no CLI flag to turn it back off.
- **CLI-only settings**: `--output`, `--baseline`, `--baseline-generate`, `--baseline-update`, `--cache-dir` and `--config` have no YAML key.

The `--config` flag lets you point to a different YAML file:

```bash
swift-cpd --config ci/swift-cpd-strict.yml Sources/
```

Unlike the default `.swift-cpd.yml`, a file passed with `--config` must exist; otherwise the run fails with `error: cannot read configuration file '<path>'` and exit code `2`.

---

## CLI Reference

### Commands

```bash
swift-cpd init                   # generate .swift-cpd.yml in the current directory
swift-cpd --version              # print version and platform, e.g. swift-cpd 1.5.0 [arm64-macos15]
swift-cpd --help                 # print usage summary
```

### Running an analysis

```bash
swift-cpd [options] [paths...]
```

Paths on the CLI override `paths:` in the YAML file. When no paths are given, the YAML file must specify them. Paths may be directories (scanned recursively) or individual files. A path that does not exist fails the run with exit code `3`; paths that contain no supported source files fail with `error: No source files found in the specified paths.` and exit code `2`.

Numeric options are range-checked after the CLI and YAML values are merged; an out-of-range value prints an error followed by the usage text and exits `2`.

### All options

| Option | Default | Valid range | Description |
|---|---|---|---|
| `--min-tokens <N>` | `50` | 10–500 | Minimum clone length in tokens |
| `--min-lines <N>` | `5` | 2–100 | Minimum clone length in lines |
| `--types <list>` | `all` | `1,2,3,4` or `all` | Clone types to detect |
| `--format <fmt>` | `text` | `text json html xcode` | Output format |
| `--output <path>` | stdout | — | Write the report to a file instead of stdout (with `--format xcode`, see [xcode](#xcode)) |
| `--exclude <pattern>` | — | glob | Exclude matching files (repeatable) |
| `--ignore-same-file` | false | — | Skip clones whose fragments are all in one file |
| `--ignore-structural` | false | — | Skip Type 3 and Type 4 clones |
| `--no-cache` | false | — | Disable tokenization cache |
| `--cache-dir <path>` | `.swift-cpd-cache` | — | Directory for the tokenization cache |
| `--cross-language` | false | — | Include Objective-C/C files |
| `--suppression-tag <tag>` | `swiftcpd:ignore` | — | Custom suppression comment tag |
| `--max-duplication <N>` | — | 0–100 | Fail if duplication % exceeds N |
| `--type3-similarity <N>` | `70` | 50–100 | Type 3 GST similarity threshold |
| `--type3-tile-size <N>` | `5` | 2–20 | Type 3 minimum tile length |
| `--type3-candidate-threshold <N>` | `30` | 10–80 | Type 3 Jaccard pre-filter |
| `--type4-similarity <N>` | `80` | 60–100 | Type 4 semantic similarity threshold |
| `--baseline-generate` | — | — | Save current clones as baseline |
| `--baseline-update` | — | — | Overwrite the baseline with current clones |
| `--baseline <path>` | `.swift-cpd-baseline.json` | — | Baseline file; on its own, compare against it |
| `--config <path>` | `.swift-cpd.yml` | — | Use a specific config file |
| `--source-ref <ref>` | — | git ref | Read sources from a git ref (see below) |
| `--version` | — | — | Print version and exit |
| `--help` | — | — | Print usage and exit |

`--types` accepts a comma-separated list of `1`–`4` (e.g. `1,2`) or `all`.

### Cache

Tokenization results are cached in `cache.json` inside `.swift-cpd-cache/` (relative to the current directory) and reused for files whose content hash is unchanged. Use `--cache-dir <path>` to place the cache elsewhere, or `--no-cache` (`noCache: true` in YAML) to skip both reading and writing the cache.

### Common invocations

```bash
# Analyze a single directory
swift-cpd Sources/

# Analyze multiple directories
swift-cpd Sources/ Plugins/

# Only exact and parameterized clones (fast, no semantic analysis)
swift-cpd --types 1,2 Sources/

# Strict: find smaller clones
swift-cpd --min-tokens 30 --min-lines 3 Sources/

# Only cross-file Type 1/2 clones
swift-cpd --ignore-same-file --ignore-structural Sources/

# Exclude test files and generated code
swift-cpd --exclude "**/*Tests*" --exclude "**/*.generated.swift" Sources/

# Save report to a file
swift-cpd --format json --output report.json Sources/

# Enable Objective-C detection for a mixed project
swift-cpd --cross-language Sources/ ObjcSources/

# Fail CI if duplication exceeds 3%
swift-cpd --max-duplication 3 Sources/

# Run without cache (useful after changing detection rules)
swift-cpd --no-cache Sources/
```

---

## Reading from a git ref (`--source-ref`)

By default `swift-cpd` reads files from the working tree. Use `--source-ref <ref>` (or `sourceRef:` in YAML) to read file contents from a git ref instead. When set, the working tree is ignored — listing, hashing, tokenization, and inline suppression all operate on the blob contents at that ref.

```bash
# Last commit
swift-cpd --source-ref HEAD Sources/

# Index (about-to-be-committed blobs)
swift-cpd --source-ref :0 Sources/

# A specific branch or sha
swift-cpd --source-ref feature/cleanup Sources/
swift-cpd --source-ref a1b2c3d Sources/
```

### When to use it

The main motivation is **`pre-commit` hooks under `git commit --only`**. In that mode, `pre-commit` stashes the working tree with `--keep-index`, producing a Frankenstein state where files in the pathspec hold their new versions while everything else reverts to `HEAD`. Running `swift-cpd` against that working tree can report duplications that don't exist in either the pre-commit or post-commit state.

Two recipes that side-step this:

```yaml
# .pre-commit-config.yaml — analyze what's about to be committed (preferred)
- repo: https://github.com/ericodx/swift-cpd
  hooks:
    - id: swift-cpd
      args: [--source-ref, ":0"]
```

```yaml
# Or run in a post-commit stage against the last commit
- repo: https://github.com/ericodx/swift-cpd
  hooks:
    - id: swift-cpd
      stages: [post-commit]
      args: [--source-ref, HEAD]
```

### Requirements & behavior notes

- **`git` must be on `PATH`.** `swift-cpd` shells out to `git rev-parse`, `git ls-tree`/`ls-files`, and `git cat-file`. A missing executable produces a clear error.
- **Reads the canonical blob bytes.** Smudge filters (`core.autocrlf`, `ident`, custom clean/smudge) are *not* applied. If the working tree differs from the blob due to those filters, that divergence is intentional with `--source-ref`.
- **Submodules are skipped** with a warning to stderr — their tree entries point at a commit, not source content.
- **Empty `--source-ref ""` is treated as unset** (reads the working tree).
- **Relative paths are resolved against the repository root**, not the current directory. Run from the repository root (or pass absolute paths) to avoid surprises.
- **Exclude patterns and `--cross-language`** apply to the files listed from the ref, as they do for the working tree.
- **Cache is namespaced by resolved sha.** Mutable refs like `HEAD` or `main` reuse the cache across runs as long as the underlying sha is unchanged. When the ref moves, the cache misses for that file.

### Output additions

When `--source-ref` is set, reports surface the ref in their header:

- **text**: header reads `Found N clone(s) in M files (at <ref>, T s)` (or the equivalent no-clones message). Without `--source-ref` the header is unchanged: `Found N clone(s) in M files (T s)`.
- **html**: the summary paragraph mirrors the text format and includes `at <ref>` when set. The ref is HTML-escaped before being rendered.
- **json**: two extra top-level keys appear next to `clones`, `metadata`, `summary`, `version`:
  ```json
  {
    "sourceRef": "HEAD",
    "resolvedSha": "a1b2c3d4…",
    "clones": [ ... ],
    ...
  }
  ```
  Both keys are **omitted entirely** when `--source-ref` is absent — existing JSON consumers are unaffected.

> **Note about `--format xcode`.** The Xcode format is designed for the SPM/Xcode build plugin, which runs against the working tree. Combining `--format xcode` with `--source-ref` produces warnings whose `file:line` come from the **blob**, but Xcode opens the corresponding **working-tree** file when you click them. If the working tree and the ref have diverged, the line shown may not contain the flagged code. Prefer `--format text` or `--format json` when analyzing a specific ref.

### Errors you may see

All of these are printed as `error: <message>` and exit with code `3`.

| Message | Cause |
|---|---|
| `notARepository(...)` | Current directory is not inside a git repo |
| `unknownRef(ref: "...")` | `git rev-parse --verify` rejected the ref |
| `gitExecutableNotFound` | `git` is not on PATH |
| `gitCommandFailed(...)` | A `git ls-tree`/`ls-files`/`cat-file` call exited with a non-zero status |
| `pathDoesNotExistInRef(...)` | A `paths:` entry has no matches in the ref's tree |
| `pathOutsideRepository(...)` | A path points outside the repository root |

---

## Output Formats

### text (default)

Human-readable output for interactive use. Prints each clone with file locations and a duplication summary.

```bash
swift-cpd --format text Sources/
```

```
Found 1 clone(s) in 47 files (1.24s)

Clone 1 (Type-1, 82 tokens, 10 lines):
  Sources/App/Cache/DiskCache.swift:14-23
  Sources/App/Cache/MemoryCache.swift:31-40
```

When nothing is found, the output is a single line: `No clones detected in 47 files (1.24s)`.

### json

Structured output for programmatic consumption. All fields are stable across versions.

```bash
swift-cpd --format json --output report.json Sources/
```

```json
{
  "clones": [
    {
      "fragments": [
        {
          "endColumn": 6,
          "endLine": 23,
          "file": "Sources/App/Cache/DiskCache.swift",
          "preview": "func store(_ value: Data, for key: String) { ... }",
          "startColumn": 5,
          "startLine": 14
        },
        {
          "endColumn": 6,
          "endLine": 40,
          "file": "Sources/App/Cache/MemoryCache.swift",
          "preview": "func store(_ value: Data, for key: String) { ... }",
          "startColumn": 5,
          "startLine": 31
        }
      ],
      "id": "clone-001",
      "lineCount": 10,
      "similarity": 100,
      "tokenCount": 82,
      "type": 1
    }
  ],
  "metadata": {
    "configuration": {
      "minimumLineCount": 5,
      "minimumTokenCount": 50
    },
    "executionTimeMs": 1240,
    "filesAnalyzed": 47,
    "timestamp": "2026-03-13T14:00:00Z",
    "totalTokens": 18430
  },
  "summary": {
    "byType": { "type1": 1, "type2": 0, "type3": 0, "type4": 0 },
    "duplicatedLines": 10,
    "duplicatedTokens": 82,
    "duplicationPercentage": 0.4,
    "totalClones": 1
  },
  "version": "swift-cpd 1.5.0 [arm64-macos15]"
}
```

Keys are sorted alphabetically. `version` is the same string `swift-cpd --version` prints. `preview` is the first line of the fragment, followed by ` ... }` when the fragment spans more than one line. `sourceRef` and `resolvedSha` are added only when `--source-ref` is set (see [Reading from a git ref](#reading-from-a-git-ref---source-ref)).

### html

A self-contained HTML report suitable for sharing or archiving.

```bash
swift-cpd --format html --output report.html Sources/
open report.html
```

### xcode

One diagnostic per fragment in the format Xcode recognizes as a build warning. Used automatically by the build plugin; rarely needed from the CLI directly.

With `--format xcode` the diagnostics are always printed to stdout and the run always exits `0`, even when clones are found or `--max-duplication` is exceeded, so that the build is never failed. If `--output <path>` is given, an empty marker file is written at that path (creating parent directories) instead of the report; the build plugin uses it as its declared output. The exception is baseline comparison (`--baseline <path>`), which writes the report like any other format and applies the normal exit codes.

```bash
swift-cpd --format xcode Sources/
```

```
/path/to/DiskCache.swift:14:5: warning: Clone detected (Type-1, 82 tokens, 10 lines) — also in MemoryCache.swift:31
/path/to/MemoryCache.swift:31:5: warning: Clone detected (Type-1, 82 tokens, 10 lines) — also in DiskCache.swift:14
```

---

## Baseline Workflow

The baseline system lets you acknowledge existing clones and report only newly introduced ones.

### Step 1 — Generate a baseline

Run once on a clean state (e.g. on `main` before introducing a feature):

```bash
swift-cpd --baseline-generate Sources/
# Baseline generated with 5 clone(s) at .swift-cpd-baseline.json
```

Commit `.swift-cpd-baseline.json` to source control. Pass `--baseline <path>` together with `--baseline-generate` (or `--baseline-update`) to write the file somewhere else. These modes only write the baseline and print the confirmation line; no report is produced.

### Step 2 — Compare against the baseline

On subsequent runs, pass `--baseline` to report only new clones:

```bash
swift-cpd --baseline .swift-cpd-baseline.json Sources/
# Only clones not present in the baseline are printed
```

Exit code is `0` if no new clones are found, `1` if there are new ones. With `--max-duplication`, the threshold is applied to the new clones only. If the baseline file does not exist, it is treated as empty and every clone is reported as new.

A clone matches a baseline entry only when its type, token count, line count and every fragment's file and line range are identical, so moving duplicated code to different lines makes it appear as new. File paths are stored as absolute paths, so a baseline only matches when the comparison runs from the same checkout location where it was generated (for example, generate and compare on the same CI runner layout).

### Step 3 — Update the baseline

After intentionally accepting new clones (e.g. after a refactor), regenerate the file. `--baseline-update` does not merge with the existing entries; it overwrites the file with the clones found in the current run:

```bash
swift-cpd --baseline-update Sources/
# Baseline updated with 7 clone(s) at .swift-cpd-baseline.json
```

> **Note:** the baseline options are CLI-only; there is no YAML key for them. `--baseline-generate` and `--baseline-update` exit `0` whenever the file is written successfully. Use them in a separate step from the comparison run.

---

## Inline Suppression

Suppress specific code regions by adding a comment with the suppression tag on its own line, immediately before the code to suppress. Tokens on suppressed lines are removed before detection runs.

The comment must be the first thing on its line (leading whitespace is allowed), start with `//` or `/*`, and the tag must be the first text inside the comment. Trailing comments such as `let x = 1 // swiftcpd:ignore` are **not** recognized. Blank lines between the comment and the code are skipped.

### Block suppression

When the next non-blank line contains a `{`, everything from that line through the matching closing `}` is suppressed, including nested braces (the opening brace must be on that line):

```swift
// swiftcpd:ignore
func legacyMigration() {
    // all tokens in this function body are excluded from analysis
    let old = fetchOldRecords()
    let new = transform(old)
    save(new)
}
```

Block comments work too:

```swift
/* swiftcpd:ignore */
class GeneratedMapper {
    // ...
}
```

### Line suppression

When the next non-blank line does not contain a `{`, only that line is suppressed:

```swift
// swiftcpd:ignore
let boilerplate = buildGenericHeader()
```

### Custom tag

Change the tag in `.swift-cpd.yml` or via CLI to avoid conflicts with other tools:

```yaml
inlineSuppressionTag: cpd:suppress
```

```bash
swift-cpd --suppression-tag "cpd:suppress" Sources/
```

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Check code duplication
  run: swift-cpd --max-duplication 5 --format json --output cpd-report.json Sources/

- name: Upload CPD report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: cpd-report
    path: cpd-report.json
    retention-days: 7
```

### Baseline comparison in pull requests

```yaml
- name: Restore baseline
  run: git show origin/main:.swift-cpd-baseline.json > .swift-cpd-baseline.json || true

- name: Check for new clones
  run: swift-cpd --baseline .swift-cpd-baseline.json Sources/
```

### Quality gate only (no report file)

```bash
# Fail the build if duplication exceeds 3%
swift-cpd --max-duplication 3 Sources/ || {
  echo "Duplication threshold exceeded"
  exit 1
}
```

### SonarQube

`swift-cpd` has no SonarQube-specific output format, and its JSON report uses its own schema (see [json](#json)) rather than a format SonarQube imports. To track duplication alongside a SonarQube analysis, run `swift-cpd` as a separate quality gate step and keep the JSON or HTML report as a build artifact, as in the [GitHub Actions](#github-actions) example above.

---

## Xcode & SPM Plugin

The `SwiftCPDPlugin` runs `swift-cpd` automatically during the build and surfaces clones as Xcode editor warnings.

### Add to an SPM target

```swift
// Package.swift
.target(
    name: "MyTarget",
    plugins: [.plugin(name: "SwiftCPDPlugin", package: "swift-cpd")]
)
```

### Add to an Xcode target

1. In Xcode, select your target → **Build Phases**
2. Click **+** → **Add Build Tool Plug-in**
3. Select **SwiftCPDPlugin**

The plugin uses `--format xcode` so every clone fragment appears as a yellow warning triangle inline in the source editor. Because the Xcode format always exits `0`, clones never fail the build.

### Plugin configuration

The plugin runs `swift-cpd --format xcode --cache-dir <plugin work dir>/cache --output <plugin work dir>/swift-cpd.marker <dir>`, where `<dir>` is the target's source directory (SPM) or the Xcode project directory. It does not pass `--config`, so `swift-cpd` loads `.swift-cpd.yml` from the working directory the build system runs it in. Because the plugin always passes a path, `paths:` in the YAML file is ignored; use `exclude:` to narrow the scope.

To suppress a region in plugin runs:

```swift
// swiftcpd:ignore
func boilerplate() {
    // ...
}
```

---

## Exit Codes

| Code | Constant | Meaning |
|---|---|---|
| `0` | `success` | No clones; or duplication at or below `maxDuplication` when it is set; always for `--format xcode` (outside baseline comparison), `--baseline-generate`, `--baseline-update`, `init`, `--help` and `--version` |
| `1` | `clonesDetected` | Clones found (new clones only in baseline comparison). When `maxDuplication` is set, only when the duplication percentage exceeds it |
| `2` | `configurationError` | Unknown flag or invalid value, value out of range, unreadable or invalid YAML file, no paths specified, no source files found, `init` when `.swift-cpd.yml` already exists |
| `3` | `analysisError` | Runtime error: a path that does not exist, a `--source-ref` error, an unreadable or invalid baseline file, a failure while reading or tokenizing sources, `init` failing to write the file |

Use exit codes in shell scripts:

```bash
swift-cpd Sources/
case $? in
  0) echo "Clean" ;;
  1) echo "Clones detected — review the report" ;;
  2) echo "Configuration error" ; exit 2 ;;
  3) echo "Analysis failed" ; exit 3 ;;
esac
```
