# Reporting

← [Detection — Type 4](08-detection-type4.md) | Next: [Cache & Baseline →](10-cache-baseline.md)

---

## Protocol

### Reporter

```swift
protocol Reporter: Sendable
func report(_ result: AnalysisResult) -> String
```

All reporters are pure value-type functions: given an `AnalysisResult`, produce a formatted string. No file I/O happens inside a reporter — the caller (`SwiftCPD.writeOutput`) handles writing.

---

## AnalysisResult

```swift
struct AnalysisResult: Sendable
```

The input to every reporter.

```swift
let cloneGroups:        [CloneGroup]
let filesAnalyzed:      Int
let executionTime:      TimeInterval
let totalTokens:        Int
let minimumTokenCount:  Int
let minimumLineCount:   Int
var filteredCloneCount: Int = 0     // removed by ignoreSameFile / ignoreStructural
var sourceRef:          String?     // value passed to --source-ref, when set
var resolvedSha:        String?     // sha resolved from sourceRef (or ":0" for the index)

var sortedCloneGroups: [CloneGroup]
```

`sortedCloneGroups` sorts by: clone type (`rawValue`) ascending → token count descending → first fragment file → first fragment start line. This order is deterministic, and every reporter iterates `sortedCloneGroups` rather than `cloneGroups`.

When `sourceRef` is set, reporters surface the ref in their output (see each implementation below). When `nil`, output stays byte-identical to pre-source-ref runs — reporters omit the new fields entirely.

---

## DuplicationCalculator

```swift
enum DuplicationCalculator
static func percentage(duplicatedTokens: Int, totalTokens: Int) -> Double
```

Returns `duplicatedTokens / totalTokens × 100`, rounded to one decimal place. Returns `0.0` when `totalTokens` is zero. Used for `summary.duplicationPercentage` in the JSON report and, in `SwiftCPD`, checked against `maxDuplication` (exit code `clonesDetected` when the percentage is strictly greater).

---

## Implementations

### TextReporter

Human-readable console output. Designed for interactive use.

- Header: total clones, files analyzed, execution time (`%.2f` seconds). When `sourceRef` is set, the header includes `at <ref>`:

  ```
  Found 4 clone(s) in 96 files (at HEAD, 0.42s)
  No clones detected in 7 files (at :0, 0.10s)
  ```

  Without `sourceRef` the format is unchanged: `Found 4 clone(s) in 96 files (0.42s)`.
- When no clones remain and `filteredCloneCount > 0`, the "No clones detected" line gets the suffix ` (N clone(s) filtered by configuration)`.
- Each clone (in `sortedCloneGroups` order, numbered from 1) is preceded by a blank line and printed as a header followed by one indented `file:startLine-endLine` line per fragment. No source preview is printed:

  ```
  Clone 1 (Type-2, 120 tokens, 15 lines):
    Sources/A.swift:10-24
    Sources/B.swift:40-54
  ```

### JsonReporter

Produces a structured JSON document. Suitable for CI integration and tooling.

```
JsonReport                      (keys encoded in sorted order)
├── clones[]          — [JsonClone]
│   ├── id · type · similarity · tokenCount · lineCount
│   └── fragments[]   — [JsonFragment]
│       ├── file · startLine · endLine · startColumn · endColumn
│       └── preview   — first source line, plus " ... }" for multi-line fragments
├── metadata          — JsonMetadata
│   ├── configuration — JsonConfiguration (minimumTokenCount · minimumLineCount)
│   ├── executionTimeMs
│   ├── filesAnalyzed
│   ├── timestamp     — ISO 8601
│   └── totalTokens
├── resolvedSha       — present only when --source-ref is set
├── sourceRef         — present only when --source-ref is set
├── summary           — JsonSummary
│   ├── byType        — JsonByType (type1 · type2 · type3 · type4 clone counts)
│   ├── duplicatedLines · duplicatedTokens
│   ├── duplicationPercentage
│   └── totalClones
└── version           — tool version string (Version.current)
```

Field details:

- `id` is `clone-001`, `clone-002`, … in `sortedCloneGroups` order; `type` is `CloneType.rawValue`.
- `executionTimeMs` is `Int(executionTime × 1000)`.
- `preview` is the fragment's first line with surrounding spaces/tabs trimmed; it is `""` when the file could not be read.
- `duplicatedTokens` / `duplicatedLines` are the sums of `tokenCount` / `lineCount` over all reported clones; `duplicationPercentage` comes from `DuplicationCalculator`.
- The encoder uses `.prettyPrinted` and `.sortedKeys`. If encoding fails, the reporter returns `{}`.

`sourceRef` and `resolvedSha` are encoded via `encodeIfPresent` — when absent, they are omitted from the output entirely. Existing consumers that don't know about them are unaffected.

`JsonReporter` reads each source file once and builds a `[String: [String]]` line cache before iterating clones, avoiding redundant disk access when a file appears in multiple clones.

The `CodingKeys` enum lives in its own file (`JsonReport+CodingKeys.swift`) as an extension on `JsonReport`. The custom `encode(to:)` calls `encodeIfPresent` for the optional ref fields and `encode` for the required ones.

### HtmlReporter

Produces a self-contained HTML page with embedded CSS. Suitable for sharing or archiving analysis results.

- The summary paragraph reads `N clone(s) found in M files (0.42s)` and follows the same `at <ref>` pattern as `TextReporter` when `sourceRef` is set.
- Each clone is a card with `Clone N`, a `Type-N` badge (CSS class `type-N`), `T tokens, L lines`, and a list of `file:startLine-endLine` fragments. No source preview is rendered.
- When no clones remain, a `No clones detected.` block is shown, with `(N clone(s) filtered by configuration)` appended when `filteredCloneCount > 0`.
- `escapeHtml` replaces only `&`, `<` and `>` (quotes are not escaped). It is applied to the ref value and to each fragment's file path.

### XcodeReporter

Produces one line per fragment in the format:

```
/path/to/File.swift:10:1: warning: Clone detected (Type-2, 120 tokens, 15 lines) — also in OtherFile.swift:42
```

The location is `file:startLine:startColumn`. The `also in` list names every *other* fragment of the same clone as `<last path component>:<startLine>`, joined with `, `. Similarity is not included. When there are no clones the output is an empty string.

This format is recognized natively by Xcode and the build plugin, surfacing clones as build warnings inline in the editor. In `SwiftCPD.handleReport`, the `xcode` format is always printed to stdout — when an output path is set, only an empty marker file is written there — and the run exits with `success`.

> **Caveat: `--format xcode` with `--source-ref`.** The Xcode format is designed for the SPM/Xcode build plugin, which runs against the working tree. When combined with `--source-ref`, warnings carry `file:line` from the blob — but Xcode opens the corresponding working-tree file when the user clicks them. If the working tree and the ref diverge, the line shown may not contain the flagged code. Prefer `text` or `json` when analyzing a specific ref.

---

← [Detection — Type 4](08-detection-type4.md) | Next: [Cache & Baseline →](10-cache-baseline.md)
