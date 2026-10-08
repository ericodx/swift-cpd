# Analysis Pipeline

← [Overview](01-overview.md) | Next: [Detection →](03-detection.md)

---

## Stages

`AnalysisPipeline` turns a list of source files into sorted clone groups. Per-file work (reading, hashing, tokenization, suppression and normalization) runs concurrently in a task group; detection then runs sequentially over the collected `FileTokens`.

```mermaid
flowchart TD
    A["CLI paths + Configuration"] --> SIO

    subgraph SIO["⓪ Source IO selection"]
        SIO1{sourceRef set?}
        SIO1 -- no --> SIO2["FilesystemSourceFileLister<br/>+ WorkingTreeSourceReader"]
        SIO1 -- yes --> SIO3["GitRefResolver → repo root + sha"]
        SIO3 --> SIO4["GitRefSourceFileLister<br/>+ GitRefSourceReader"]
    end

    SIO --> A1[Source file paths]
    A1 --> L["Load cache.json<br/>(unless cache disabled)"]
    L --> B

    subgraph B["① Per-file processing (task group, async)"]
        B1["SourceReader.read(file:) → Data"] --> B2["FileHasher.hash(data:)"]
        B2 --> B3{Cache hit?}
        B3 -- yes --> B4[Load cached tokens]
        B3 -- no --> B5["Tokenize<br/>SwiftTokenizer · CTokenizer"]
        B5 --> B6[Apply UnifiedTokenMapper<br/>if cross-language]
        B6 --> B7[Drop tokens on lines<br/>suppressed by swiftcpd:ignore]
        B7 --> B8[TokenNormalizer]
        B8 --> B9[Store in cache]
    end

    B --> S["Save cache.json<br/>(unless cache disabled)"]
    S --> D["FileTokens array (sorted by file)"]

    D --> E

    subgraph E["② Detection (sequential)"]
        E1[CloneDetector<br/>Type 1 · Type 2]
        E2[Type3Detector<br/>Type 3]
        E3[Type4Detector<br/>Type 4]
    end

    E --> F[Merge · keep enabled clone types]
    F --> G["Sort by type → file → startLine"]
    G --> H[PipelineResult]
```

Only detectors whose supported clone types intersect `enabledCloneTypes` are run. Each detector deduplicates its own output (see [Detection](03-detection.md)); the pipeline itself only concatenates the results and drops groups of disabled types. Filtering by `ignoreSameFile` / `ignoreStructural` and baseline comparison happen afterwards in `SwiftCPD`, not in the pipeline.

### Stage 0 — Source IO selection

Before the pipeline kicks in, `SwiftCPD.runAnalysis` picks the right source backends from `Configuration`:

| `sourceRef` | `SourceFileLister` | `SourceReader` | Cache key namespace |
|---|---|---|---|
| `nil` (default) | `FilesystemSourceFileLister` | `WorkingTreeSourceReader` | path only |
| `HEAD`, branch, sha | `GitRefSourceFileLister` | `GitRefSourceReader` | `<resolvedSha>\|<path>` |
| `:0` (index) | `GitRefSourceFileLister` | `GitRefSourceReader` | `:0\|<path>` |

The git variants shell out to `git ls-tree -r <sha>` (or `git ls-files --stage` for `:0`) for discovery and `git cat-file blob <sha>:<path>` for content. Submodule entries are skipped with a warning on stderr. `GitRefResolver` runs `git rev-parse --show-toplevel` and, for any ref other than `:0`, `git rev-parse --verify --quiet <ref>` once, producing the repo root and a resolved sha that is reused for every file in the analysis. For `:0` the resolved sha is the literal `:0`.

## Key Data Structures

### FileTokens

The central artifact produced by stage 1 and consumed by all detectors.

```
FileTokens
├── file          — absolute path
├── source        — raw source text
├── tokens        — original tokens (with real identifiers/literals)
└── normalizedTokens — tokens with $ID / $NUM / $STR placeholders
```

Both token lists are always co-indexed: `tokens[i]` and `normalizedTokens[i]` refer to the same source position.

### Token

```
Token
├── kind     — keyword · identifier · typeName · integerLiteral · ...
├── text     — original or normalized text
└── location — SourceLocation (file · line · column)
```

## Concurrency Model

| Component | Concurrency |
|---|---|
| Per-file processing | `withThrowingTaskGroup`, one child task per file |
| `FileCache` | `actor` — serialized reads and writes |
| `ProgressReporter` | `struct` backed by the `ProgressState` actor — prints `Analyzing N files...` to stderr after 5 s (text format only) |
| Detectors | Called sequentially on the collected `FileTokens` |

The detectors themselves are pure value-type functions (`struct` conforming to `DetectionAlgorithm`) and require no synchronization.

## Configuration Thresholds

Pipeline parameters live inside three nested option structs on `AnalysisPipeline`.

**`DetectionOptions`** — detection-time knobs:

| Parameter | Default | Purpose |
|---|---|---|
| `minimumTokenCount` | 50 | Minimum clone size (in tokens) |
| `minimumLineCount` | 5 | Minimum clone size (in lines) |
| `thresholds.type3Similarity` | 70% | Minimum GST similarity for Type 3 |
| `thresholds.type3TileSize` | 5 | Minimum matching tile length |
| `thresholds.type3CandidateThreshold` | 30% | Jaccard pre-filter for Type 3 |
| `thresholds.type4Similarity` | 80% | Minimum combined similarity for Type 4 |
| `enabledCloneTypes` | all four | Which clone types to run |
| `crossLanguageEnabled` | `false` | Map C-family tokens to Swift equivalents |
| `inlineSuppressionTag` | `swiftcpd:ignore` | Comment tag for inline suppression |

**`CacheOptions`** — on-disk cache:

| Parameter | Default | Purpose |
|---|---|---|
| `directory` | _(required; `AnalysisPipeline.init` defaults to `.swift-cpd-cache`)_ | Where `cache.json` lives |
| `disabled` | `false` | Bypass cache reads/writes entirely |

**`SourceOptions`** — where bytes come from:

| Parameter | Default | Purpose |
|---|---|---|
| `reader` | `WorkingTreeSourceReader()` | Implementation of `SourceReader` |
| `resolvedSha` | `nil` | When set, namespaces cache entries by this sha so runs against different refs don't collide |

---

← [Overview](01-overview.md) | Next: [Detection →](03-detection.md)
