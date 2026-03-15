# CodeBase Reference

Detailed documentation of every type, protocol, and algorithm in `swift-cpd`. For a higher-level view see [`Docs/Architecture`](../Architecture/README.md).

## Documents

| # | Document | Types covered |
|---|---|---|
| 01 | [CLI & Configuration](01-cli-configuration.md) | `ArgumentParser` · `ParsedArguments` · `Configuration` · `OutputFormat` · `BaselineMode` · `ExitCode` · `SourcePathDiscovery` |
| 02 | [File Discovery](02-file-discovery.md) | `SourceFileDiscovery` · `GlobMatcher` · `FileDiscoveryError` |
| 03 | [Tokenization](03-tokenization.md) | `Token` · `TokenKind` · `SourceLocation` · `SwiftTokenizer` · `CTokenizer` · `TokenNormalizer` · `UnifiedTokenMapper` · `SuppressionScanner` |
| 04 | [Pipeline](04-pipeline.md) | `AnalysisPipeline` · `DetectionThresholds` · `PipelineResult` · `ProgressReporter` · `ProgressState` |
| 05 | [Detection — Core](05-detection-core.md) | `DetectionAlgorithm` · `CloneType` · `CloneGroup` · `CloneFragment` · `FileTokens` · `CodeBlock` · `IndexedBlock` · `BlockExtraction` · `BlockExtractor` · `BlockVisitor` · `RangedSyntaxVisitor` · `CloneGroupDeduplicator` |
| 06 | [Detection — Type 1 & 2](06-detection-type12.md) | `CloneDetector` · `RollingHash` · `TokenLocation` · `ClonePair` · `ClassifiedClonePair` |
| 07 | [Detection — Type 3](07-detection-type3.md) | `Type3Detector` · `BlockFingerprint` · `BagJaccardSimilarity` · `GreedyStringTiler` · `GreedyTilingState` · `TileMatch` |
| 08 | [Detection — Type 4](08-detection-type4.md) | `Type4Detector` · `BehaviorSignature` · `BehaviorSignatureExtractor` · `BehaviorSignatureComparer` · `AbstractSemanticGraph` · `SemanticNormalizer` · `ASGComparer` · and more |
| 09 | [Reporting](09-reporting.md) | `Reporter` · `AnalysisResult` · `TextReporter` · `JsonReporter` · `HtmlReporter` · `XcodeReporter` · `DuplicationCalculator` |
| 10 | [Cache & Baseline](10-cache-baseline.md) | `FileCache` · `CacheEntry` · `FileHasher` · `BaselineStore` · `BaselineEntry` · `FragmentFingerprint` |
| 11 | [Plugin](11-plugin.md) | `SwiftCPDPlugin` |
