# Pipeline

Orchestrates the analysis pipeline: tokenization, caching, detection, and progress reporting.

## Files

- `Sources/SwiftCPD/Pipeline/AnalysisPipeline.swift`
- `Sources/SwiftCPD/Pipeline/PipelineResult.swift`
- `Sources/SwiftCPD/Pipeline/ProgressReporter.swift`
- `Sources/SwiftCPD/Pipeline/ProgressState.swift`

---

## AnalysisPipeline

`struct AnalysisPipeline: Sendable`

The central orchestrator. Coordinates file tokenization (parallel via `TaskGroup`), [caching](Cache.md), and [detection](Detection.md) algorithms.

### Properties

| Property | Type | Default |
|---|---|---|
| `minimumTokenCount` | `Int` | `50` |
| `minimumLineCount` | `Int` | `5` |
| `cacheDirectory` | `String` | `".swiftcpd-cache"` |
| `crossLanguageEnabled` | `Bool` | `false` |
| `type3Similarity` | `Int` | `70` |
| `type3TileSize` | `Int` | `5` |
| `type3CandidateThreshold` | `Int` | `30` |
| `type4Similarity` | `Int` | `80` |
| `enabledCloneTypes` | `Set<CloneType>` | all types |

### Internal Components

| Component | Type | Description |
|---|---|---|
| `swiftTokenizer` | [SwiftTokenizer](Tokenization.md#swifttokenizer) | Tokenizes Swift files |
| `cTokenizer` | [CTokenizer](Tokenization.md#ctokenizer) | Tokenizes C-family files |
| `unifiedMapper` | [UnifiedTokenMapper](Tokenization.md#unifiedtokenmapper) | Cross-language token mapping |
| `normalizer` | [TokenNormalizer](Tokenization.md#tokennormalizer) | Token normalization |
| `suppressionScanner` | [SuppressionScanner](Suppression.md) | Inline suppression |
| `hasher` | [FileHasher](Cache.md#filehasher) | SHA-256 file hashing |

### Methods

| Method | Signature | Description |
|---|---|---|
| `analyze` | `(files: [String]) async throws -> PipelineResult` | Runs the full pipeline |
| `buildDetectors` | `() -> [any DetectionAlgorithm]` | Creates detectors for enabled types |
| `processFiles` | `(_ files: [String], cache: FileCache) async throws -> [FileTokens]` | Parallel tokenization with caching |
| `tokenizeFile` | `(_ filePath: String, cache: FileCache) async throws -> FileTokens` | Tokenizes a single file |

### Pipeline Steps

1. Load [file cache](Cache.md)
2. Tokenize all files in parallel (`TaskGroup`)
3. Save updated cache
4. Build [detectors](Detection.md) based on enabled clone types
5. Run each detector and collect clone groups
6. Return `PipelineResult`

---

## PipelineResult

`struct PipelineResult: Sendable, Equatable`

Output of the analysis pipeline.

| Property | Type | Description |
|---|---|---|
| `cloneGroups` | `[CloneGroup]` | All detected clone groups |
| `totalTokens` | `Int` | Total token count across all files |

---

## ProgressReporter

`struct ProgressReporter: Sendable`

Writes progress messages to stderr after a configurable delay. Used only for text output format to avoid noise in structured outputs.

| Property | Type | Default |
|---|---|---|
| `totalFiles` | `Int` | (required) |
| `delayNanoseconds` | `UInt64` | `5_000_000_000` (5 seconds) |

| Method | Signature | Description |
|---|---|---|
| `start` | `()` | Starts a delayed progress message task |
| `stop` | `() async` | Cancels the progress task |
| `writeProgress` | `(_ message: String)` | Writes to stderr |

---

## ProgressState

`actor ProgressState`

Manages the lifecycle of the progress reporting task. Uses actor isolation to safely store and cancel the task from concurrent contexts.

| Method | Signature | Description |
|---|---|---|
| `storeTask` | `(_ task: Task<Void, any Error>)` | Stores the progress task |
| `cancelTask` | `()` | Cancels and clears the task |
