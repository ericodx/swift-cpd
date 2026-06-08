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

`sortedCloneGroups` sorts by: clone type ascending → token count descending → first fragment file → first fragment start line. This order is deterministic and is the order used in all reports.

When `sourceRef` is set, reporters surface the ref in their output (see each implementation below). When `nil`, output stays byte-identical to pre-source-ref runs — reporters omit the new fields entirely.

---

## DuplicationCalculator

```swift
enum DuplicationCalculator
static func percentage(duplicatedTokens: Int, totalTokens: Int) -> Double
```

Returns `duplicatedTokens / totalTokens × 100`. Returns `0.0` when `totalTokens` is zero. Used to compute the duplication percentage shown in reports and checked against `maxDuplication`.

---

## Implementations

### TextReporter

Human-readable console output. Designed for interactive use.

- Groups clones by type.
- For each clone: prints fragment locations and a source preview.
- Header: total clones, files analyzed, execution time. When `sourceRef` is set, the header includes `at <ref>`:

  ```
  Found 4 clone(s) in 96 files (at HEAD, 0.42s)
  No clones detected in 7 files (at :0, 0.10s)
  ```

  Without `sourceRef` the format is unchanged: `Found 4 clone(s) in 96 files (0.42s)`.

### JsonReporter

Produces a structured JSON document. Suitable for CI integration and tooling.

```
JsonReport
├── metadata       — JsonMetadata
│   ├── version    — tool version string
│   ├── timestamp  — ISO 8601
│   └── executionTime
├── configuration  — JsonConfiguration (thresholds and flags used)
├── summary        — JsonSummary
│   ├── totalClones
│   ├── filesAnalyzed
│   ├── totalTokens
│   └── duplicationPercentage
├── byType         — JsonByType (clone counts per type)
├── sourceRef      — present only when --source-ref is set
├── resolvedSha    — present only when --source-ref is set
└── clones[]       — [JsonClone]
    ├── type · similarity · tokenCount · lineCount
    └── fragments[]
        ├── file · startLine · endLine · startColumn · endColumn
        └── preview   — source lines read from disk
```

`sourceRef` and `resolvedSha` are encoded via `encodeIfPresent` — when absent, they are omitted from the output entirely. Existing consumers that don't know about them are unaffected.

`JsonReporter` reads each source file once and builds a `[String: [String]]` line cache before iterating clones, avoiding redundant disk access when a file appears in multiple clones.

The `CodingKeys` enum lives in its own file (`JsonReport+CodingKeys.swift`) as an extension on `JsonReport`. The custom `encode(to:)` calls `encodeIfPresent` for the optional ref fields and `encode` for the required ones.

### HtmlReporter

Produces a self-contained HTML page with embedded CSS. Suitable for sharing or archiving analysis results.

The summary paragraph at the top of the page follows the same `at <ref>` pattern as `TextReporter`. The ref value is passed through `escapeHtml` before being rendered.

### XcodeReporter

Produces one line per fragment in the format:

```
/path/to/File.swift:10:1: warning: Clone detected (Type 2, 120 tokens, 15 lines, 100.0% similarity)
```

This format is recognized natively by Xcode and the build plugin, surfacing clones as build warnings inline in the editor.

> **Caveat: `--format xcode` with `--source-ref`.** The Xcode format is designed for the SPM/Xcode build plugin, which runs against the working tree. When combined with `--source-ref`, warnings carry `file:line` from the blob — but Xcode opens the corresponding working-tree file when the user clicks them. If the working tree and the ref diverge, the line shown may not contain the flagged code. Prefer `text` or `json` when analyzing a specific ref.

---

← [Detection — Type 4](08-detection-type4.md) | Next: [Cache & Baseline →](10-cache-baseline.md)
