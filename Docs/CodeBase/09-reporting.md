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
let cloneGroups:      [CloneGroup]
let filesAnalyzed:    Int
let executionTime:    TimeInterval
let totalTokens:      Int
let minimumTokenCount: Int
let minimumLineCount:  Int

var sortedCloneGroups: [CloneGroup]
```

`sortedCloneGroups` sorts by: clone type ascending → token count descending → first fragment file → first fragment start line. This order is deterministic and is the order used in all reports.

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
- Footer: total clones, files analyzed, duplication percentage, execution time.

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
└── clones[]       — [JsonClone]
    ├── type · similarity · tokenCount · lineCount
    └── fragments[]
        ├── file · startLine · endLine · startColumn · endColumn
        └── preview   — source lines read from disk
```

`JsonReporter` reads each source file once and builds a `[String: [String]]` line cache before iterating clones, avoiding redundant disk access when a file appears in multiple clones.

### HtmlReporter

Produces a self-contained HTML page with embedded CSS. Suitable for sharing or archiving analysis results.

### XcodeReporter

Produces one line per fragment in the format:

```
/path/to/File.swift:10:1: warning: Clone detected (Type 2, 120 tokens, 15 lines, 100.0% similarity)
```

This format is recognized natively by Xcode and the build plugin, surfacing clones as build warnings inline in the editor.

---

← [Detection — Type 4](08-detection-type4.md) | Next: [Cache & Baseline →](10-cache-baseline.md)
