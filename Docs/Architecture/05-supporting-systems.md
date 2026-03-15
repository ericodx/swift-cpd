# Supporting Systems

← [Tokenization](04-tokenization.md) | [Index →](README.md)

---

## Configuration

Configuration is assembled from two sources that are merged, with CLI arguments taking precedence over the YAML file.

```mermaid
flowchart TD
    A[CLI arguments] --> C[Configuration]
    B[".swift-cpd.yml"] --> C
    C --> D[AnalysisPipeline]
    C --> E[Reporter]
    C --> F[BaselineStore]
```

**`YamlConfigurationParser`** is a zero-dependency YAML parser. It handles scalar values (strings, integers, booleans) and single-level lists. There is no external YAML library.

### Key Configuration Fields

| Field | Default | Description |
|---|---|---|
| `paths` | _(required)_ | Source directories to analyze |
| `minimumTokenCount` | 50 | Smallest clone in tokens |
| `minimumLineCount` | 5 | Smallest clone in lines |
| `outputFormat` | `text` | `text` · `json` · `html` · `xcode` |
| `enabledCloneTypes` | `[1,2,3,4]` | Which clone types to run |
| `ignoreSameFile` | `true` | Skip clones within a single file |
| `ignoreStructural` | `true` | Skip Type 3 and Type 4 clones |
| `crossLanguageEnabled` | `false` | Include Objective-C/C files |
| `inlineSuppressionTag` | `swiftcpd:ignore` | Comment tag to suppress a region |
| `maxDuplication` | _(none)_ | Fail if duplication % exceeds this |
| `baselineFilePath` | `.swift-cpd-baseline.json` | Baseline file location |
| `cacheDirectory` | `.swift-cpd-cache` | Token cache directory |

### `init` Command — Source Path Discovery

`swift-cpd init` generates a starter `.swift-cpd.yml` with the `paths` field set automatically by `SourcePathDiscovery`:

```mermaid
flowchart TD
    A{Sources/ exists?} -- yes --> B["paths: [Sources/]"]
    A -- no --> C[Scan top-level directories]
    C --> D{Contains .swift files?}
    D -- yes --> E[Include directory]
    D -- no --> F[Skip]
    E --> G[Exclude: .build · DerivedData · Pods · Carthage · ...]
    G --> H{Any found?}
    H -- yes --> I[Use discovered paths]
    H -- no --> J["Fallback: paths: [Sources/]"]
```

---

## Cache

`FileCache` is an `actor` that stores tokenization results on disk. It eliminates redundant tokenization on unchanged files.

```mermaid
flowchart TD
    A[File path + content hash] --> B{Entry exists<br/>and hash matches?}
    B -- yes --> C[Return cached tokens]
    B -- no --> D[Tokenize + normalize]
    D --> E[Update actor state]
    E --> F[Persist to cache.json]
    D --> G[Return fresh tokens]
```

**Cache entry:**

```
CacheEntry
├── contentHash  — SHA-256 of file contents
├── tokens       — original Token list
└── normalizedTokens — normalized Token list
```

The cache is stored at `.swift-cpd-cache/cache.json` (configurable). I/O operations are offloaded to a `Task.detached` to avoid blocking the actor while the caller awaits the result.

---

## Baseline

The baseline system enables incremental analysis: only clones introduced since the last recorded state are reported.

```mermaid
flowchart TD
    A{Baseline mode?}
    A -- generate --> B[Save all current clones to baseline file]
    A -- update --> B
    A -- compare --> C[Load baseline from file]
    C --> D[Current analysis result]
    D --> E[Filter: remove clones matching baseline]
    E --> F[Report only new clones]
    A -- none --> G[Report all clones]
```

### Matching Strategy

Clones are identified in the baseline by a `FragmentFingerprint` (file path + start/end lines), not by exact byte positions. This makes the baseline tolerant of minor source edits that shift line numbers within unchanged code.

**BaselineEntry:**

```
BaselineEntry
├── type                 — clone type (1–4)
├── tokenCount
├── lineCount
└── fragmentFingerprints — [FragmentFingerprint]
                           (file · startLine · endLine)
```

---

## Reporting

All reporters implement the `Reporter` protocol and receive a single `AnalysisResult` value.

```mermaid
flowchart TD
    AR[AnalysisResult] --> SEL{outputFormat}
    SEL -- text --> TR[TextReporter<br/>human-readable console output]
    SEL -- json --> JR[JsonReporter<br/>structured JSON with metadata]
    SEL -- html --> HR[HtmlReporter<br/>self-contained HTML page]
    SEL -- xcode --> XR[XcodeReporter<br/>file:line: warning: … format]
```

**`AnalysisResult`** contains:
- `cloneGroups` — sorted by type → token count → file → line
- `filesAnalyzed`, `executionTime`, `totalTokens`
- `minimumTokenCount`, `minimumLineCount` (for context in reports)

**`DuplicationCalculator`** computes the percentage: `duplicatedTokens / totalTokens × 100`. When `maxDuplication` is configured, the exit code becomes `1` (clonesDetected) if this percentage is exceeded.

### JSON Report Structure

```
JsonReport
├── metadata     — tool version, timestamp, execution time
├── configuration — thresholds and flags used
├── summary      — total clones, files, duplication %
├── byType       — clone counts grouped by type
└── clones[]
    ├── type · similarity · tokenCount · lineCount
    └── fragments[]
        ├── file · startLine · endLine
        └── preview  — source lines for context
```

---

← [Tokenization](04-tokenization.md) | [Index →](README.md)
