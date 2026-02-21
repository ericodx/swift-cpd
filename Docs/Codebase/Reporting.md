# Reporting

Formats analysis results into different output formats. All reporters conform to the `Reporter` protocol.

## Files

- `Sources/SwiftCPD/Reporting/Reporter.swift`
- `Sources/SwiftCPD/Reporting/AnalysisResult.swift`
- `Sources/SwiftCPD/Reporting/DuplicationCalculator.swift`
- `Sources/SwiftCPD/Reporting/TextReporter.swift`
- `Sources/SwiftCPD/Reporting/JsonReporter.swift`
- `Sources/SwiftCPD/Reporting/JsonReport.swift`
- `Sources/SwiftCPD/Reporting/JsonMetadata.swift`
- `Sources/SwiftCPD/Reporting/JsonConfiguration.swift`
- `Sources/SwiftCPD/Reporting/JsonClone.swift`
- `Sources/SwiftCPD/Reporting/JsonFragment.swift`
- `Sources/SwiftCPD/Reporting/JsonSummary.swift`
- `Sources/SwiftCPD/Reporting/JsonByType.swift`
- `Sources/SwiftCPD/Reporting/HtmlReporter.swift`
- `Sources/SwiftCPD/Reporting/XcodeReporter.swift`

---

## Reporter

`protocol Reporter: Sendable`

| Requirement | Signature |
|---|---|
| `report` | `func report(_ result: AnalysisResult) -> String` |

---

## AnalysisResult

`struct AnalysisResult: Sendable`

Wraps all data needed by reporters.

| Property | Type | Description |
|---|---|---|
| `cloneGroups` | `[CloneGroup]` | Detected clones |
| `filesAnalyzed` | `Int` | Number of files processed |
| `executionTime` | `TimeInterval` | Analysis duration in seconds |
| `totalTokens` | `Int` | Total token count across all files |
| `minimumTokenCount` | `Int` | Configured minimum token threshold |
| `minimumLineCount` | `Int` | Configured minimum line threshold |

| Computed Property | Type | Description |
|---|---|---|
| `sortedCloneGroups` | `[CloneGroup]` | Sorted by type, token count, file, line |

---

## DuplicationCalculator

`enum DuplicationCalculator`

| Method | Signature | Description |
|---|---|---|
| `percentage` | `(duplicatedTokens: Int, totalTokens: Int) -> Double` | `(duplicated / total) * 100`, rounded to 1 decimal |

---

## TextReporter

`struct TextReporter: Reporter`

Human-readable output format. Produces a summary line and a list of clones with their locations.

**Example output:**

```
Found 3 clone(s) in 10 files (0.25s)

Clone 1 (Type-1, 50 tokens, 10 lines):
  /path/to/file1.swift:10-20
  /path/to/file2.swift:30-40
```

---

## JsonReporter

`struct JsonReporter: Reporter`

Structured JSON output with metadata, summary, and detailed clone information.

### JSON Structure

| Top-Level Key | Content |
|---|---|
| `version` | Schema version (`"1.0.0"`) |
| `metadata` | Configuration, execution time, files analyzed, timestamp, total tokens |
| `summary` | Counts by type, duplicated lines/tokens, duplication percentage, total clones |
| `clones` | Array of clones with fragments, ID, line/token count, similarity, type |

Each fragment includes a `preview` field with the first line of the cloned code.

### Related Types

| Type | File | Properties |
|---|---|---|
| `JsonReport` | `JsonReport.swift` | `clones`, `metadata`, `summary`, `version` |
| `JsonMetadata` | `JsonMetadata.swift` | `configuration`, `executionTimeMs`, `filesAnalyzed`, `timestamp`, `totalTokens` |
| `JsonConfiguration` | `JsonConfiguration.swift` | `minimumLineCount`, `minimumTokenCount` |
| `JsonClone` | `JsonClone.swift` | `fragments`, `id`, `lineCount`, `similarity`, `tokenCount`, `type` |
| `JsonFragment` | `JsonFragment.swift` | `endColumn`, `endLine`, `file`, `preview`, `startColumn`, `startLine` |
| `JsonSummary` | `JsonSummary.swift` | `byType`, `duplicatedLines`, `duplicatedTokens`, `duplicationPercentage`, `totalClones` |
| `JsonByType` | `JsonByType.swift` | `type1`, `type2`, `type3`, `type4` |

---

## HtmlReporter

`struct HtmlReporter: Reporter`

Generates a standalone HTML page with embedded CSS. Each clone is displayed as a card with a color-coded badge.

| Clone Type | Badge Color |
|---|---|
| Type-1 | Green |
| Type-2 | Blue |
| Type-3 | Orange |
| Type-4 | Red |

---

## XcodeReporter

`struct XcodeReporter: Reporter`

Outputs warnings in Xcode-compatible format for build system integration.

**Format:** `file:line:column: warning: Clone detected (Type-N, X tokens, Y lines) - also in other_file.swift:line`

Each fragment in a clone group generates a separate warning line, referencing the other fragment locations.
