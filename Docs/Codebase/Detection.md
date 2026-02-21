# Detection

Clone detection algorithms for all four clone types. Each algorithm conforms to the `DetectionAlgorithm` protocol.

See also: [SemanticGraph](SemanticGraph.md) for Type-4 graph structures.

## Files

- `Sources/SwiftCPD/Detection/DetectionAlgorithm.swift`
- `Sources/SwiftCPD/Detection/CloneType.swift`
- `Sources/SwiftCPD/Detection/CloneGroup.swift`
- `Sources/SwiftCPD/Detection/CloneFragment.swift`
- `Sources/SwiftCPD/Detection/FileTokens.swift`
- `Sources/SwiftCPD/Detection/CloneDetector.swift`
- `Sources/SwiftCPD/Detection/TokenLocation.swift`
- `Sources/SwiftCPD/Detection/ClonePair.swift`
- `Sources/SwiftCPD/Detection/ClassifiedPair.swift`
- `Sources/SwiftCPD/Detection/RollingHash.swift`
- `Sources/SwiftCPD/Detection/Type3Detector.swift`
- `Sources/SwiftCPD/Detection/Type3CandidatePair.swift`
- `Sources/SwiftCPD/Detection/CodeBlock.swift`
- `Sources/SwiftCPD/Detection/BlockExtractor.swift`
- `Sources/SwiftCPD/Detection/BlockVisitor.swift`
- `Sources/SwiftCPD/Detection/BlockExtraction.swift`
- `Sources/SwiftCPD/Detection/BlockFingerprint.swift`
- `Sources/SwiftCPD/Detection/GreedyStringTiler.swift`
- `Sources/SwiftCPD/Detection/TileMatch.swift`
- `Sources/SwiftCPD/Detection/TilingState.swift`
- `Sources/SwiftCPD/Detection/CloneGroupBuilder.swift`
- `Sources/SwiftCPD/Detection/CloneGroupDeduplicator.swift`
- `Sources/SwiftCPD/Detection/IndexedBlock.swift`
- `Sources/SwiftCPD/Detection/IndexedBlockPair.swift`
- `Sources/SwiftCPD/Detection/Type4Detector.swift`
- `Sources/SwiftCPD/Detection/Type4CandidatePair.swift`
- `Sources/SwiftCPD/Detection/SignedBlock.swift`
- `Sources/SwiftCPD/Detection/BehaviorSignature.swift`
- `Sources/SwiftCPD/Detection/BehaviorSignatureExtractor.swift`
- `Sources/SwiftCPD/Detection/BehaviorSignatureComparer.swift`
- `Sources/SwiftCPD/Detection/LCSCalculator.swift`
- `Sources/SwiftCPD/Detection/ControlFlowNode.swift`
- `Sources/SwiftCPD/Detection/DataFlowPattern.swift`
- `Sources/SwiftCPD/Detection/RangedSyntaxVisitor.swift`

---

## DetectionAlgorithm

`protocol DetectionAlgorithm: Sendable`

| Requirement | Signature |
|---|---|
| `supportedCloneTypes` | `var supportedCloneTypes: Set<CloneType> { get }` |
| `detect` | `func detect(files: [FileTokens], sources: [String: String]) -> [CloneGroup]` |

---

## Core Types

### CloneType

`enum CloneType: Int, Sendable, Equatable, Hashable, CaseIterable`

| Case | Value | Description |
|---|---|---|
| `type1` | `1` | Exact clones |
| `type2` | `2` | Parameterized clones (renamed identifiers/literals) |
| `type3` | `3` | Gapped clones (insertions/deletions) |
| `type4` | `4` | Semantic clones (different implementation, same logic) |

### CloneGroup

`struct CloneGroup: Sendable, Equatable, Hashable`

A group of code fragments that are clones of each other.

| Property | Type | Description |
|---|---|---|
| `type` | `CloneType` | Classification of the clone |
| `tokenCount` | `Int` | Number of tokens in the cloned region |
| `lineCount` | `Int` | Number of lines in the cloned region |
| `similarity` | `Double` | Similarity percentage (100.0 for Type-1) |
| `fragments` | `[CloneFragment]` | Locations of each clone instance |

| Computed Property | Type | Description |
|---|---|---|
| `isSameFile` | `Bool` | `true` if all fragments belong to the same file |
| `isStructural` | `Bool` | `true` if the clone is Type-3 or Type-4 |

### CloneFragment

`struct CloneFragment: Sendable, Equatable, Hashable`

A single clone location within a source file.

| Property | Type |
|---|---|
| `file` | `String` |
| `startLine` | `Int` |
| `endLine` | `Int` |
| `startColumn` | `Int` |
| `endColumn` | `Int` |

### FileTokens

`struct FileTokens: Sendable`

Tokens for a single file, used as input to detection algorithms.

| Property | Type | Description |
|---|---|---|
| `file` | `String` | File path |
| `tokens` | `[Token]` | Raw tokens |
| `normalizedTokens` | `[Token]` | Normalized tokens (placeholders applied) |

---

## CloneDetector (Type-1 + Type-2)

`struct CloneDetector: DetectionAlgorithm`

Detects exact and parameterized clones using a rolling hash technique.

### Algorithm

1. **Find candidates**: Build hash table of all token windows (size = `minimumTokenCount`) using `RollingHash`
2. **Verify candidates**: For hash collisions, verify actual token equality
3. **Expand regions**: Extend matching regions forward and backward
4. **Classify**: Type-1 if raw tokens match, Type-2 if only normalized tokens match
5. **Deduplicate**: Remove subsumed clones
6. **Filter**: Apply minimum line count threshold

### Properties

| Property | Type | Default |
|---|---|---|
| `minimumTokenCount` | `Int` | `50` |
| `minimumLineCount` | `Int` | `5` |

### Related Types

| Type | File | Properties |
|---|---|---|
| `TokenLocation` | `TokenLocation.swift` | `fileIndex: Int`, `offset: Int` |
| `ClonePair` | `ClonePair.swift` | `locationA`, `locationB`, `tokenCount` |
| `ClassifiedPair` | `ClassifiedPair.swift` | `type`, `tokenCount`, `locationA`, `locationB` |

---

## RollingHash

`struct RollingHash: Sendable`

Polynomial rolling hash for efficient token window matching.

- Base: `31`
- Modulus: `1_000_000_007`

| Method | Signature | Description |
|---|---|---|
| `hash` | `(_ tokens: [Token], offset: Int, count: Int) -> UInt64` | Hash a token window |
| `rollingUpdate` | `(hash:removing:adding:highestPower:) -> UInt64` | Slide window by one position |
| `power` | `(for windowSize: Int) -> UInt64` | Precompute highest power |

---

## Type3Detector (Type-3)

`struct Type3Detector: DetectionAlgorithm`

Detects gapped clones using Greedy String Tiling on code blocks.

### Algorithm

1. **Extract blocks**: Use `BlockExtractor` to find functions, methods, closures via SwiftSyntax
2. **Pre-filter**: Compare block pairs using Jaccard similarity on `BlockFingerprint` (token frequencies)
3. **Compute similarity**: Run `GreedyStringTiler` on candidate pairs
4. **Deduplicate**: Remove subsumed clones

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `similarityThreshold` | `Double` | `70.0` | Minimum similarity to report |
| `minimumTileSize` | `Int` | `5` | Minimum tile size for GST |
| `candidateFilterThreshold` | `Double` | `30.0` | Jaccard pre-filter threshold |
| `minimumTokenCount` | `Int` | `50` | Minimum tokens per block |
| `minimumLineCount` | `Int` | `5` | Minimum lines per block |

---

## CodeBlock

`struct CodeBlock: Sendable, Equatable`

A contiguous block of code (function, method, closure).

| Property | Type | Description |
|---|---|---|
| `file` | `String` | File path |
| `startLine` | `Int` | First line of the block |
| `endLine` | `Int` | Last line of the block |
| `startTokenIndex` | `Int` | Index into the file's token array |
| `endTokenIndex` | `Int` | End index (exclusive) |

---

## BlockExtractor

`struct BlockExtractor: Sendable`

Extracts code blocks from Swift source using a SwiftSyntax `SyntaxVisitor`. Visits:

- `FunctionDeclSyntax`
- `InitializerDeclSyntax`
- `AccessorDeclSyntax`
- `ClosureExprSyntax`

| Method | Signature |
|---|---|
| `extract` | `(source: String, file: String, tokens: [Token]) -> [CodeBlock]` |

---

## BlockFingerprint

`struct BlockFingerprint: Sendable, Equatable`

Token frequency map for a code block. Used for fast pre-filtering of candidate pairs.

| Property | Type |
|---|---|
| `tokenFrequencies` | `[String: Int]` |

| Method | Signature | Description |
|---|---|---|
| `init` | `(tokens: [Token], startIndex: Int, endIndex: Int)` | Builds frequency map |
| `jaccardSimilarity` | `(with other: BlockFingerprint) -> Double` | Jaccard index on frequency bags |

---

## GreedyStringTiler

`struct GreedyStringTiler: Sendable`

Implements the Greedy String Tiling algorithm. Iteratively finds the longest matching tiles between two token sequences, marks matched tokens as covered, and computes similarity.

**Formula**: `similarity = 2 * totalCovered / (lengthA + lengthB)`

| Property | Type | Default |
|---|---|---|
| `minimumTileSize` | `Int` | `5` |

| Method | Signature |
|---|---|
| `similarity` | `(between tokensA: [Token], and tokensB: [Token]) -> Double` |

### Related Types

| Type | File | Properties |
|---|---|---|
| `TileMatch` | `TileMatch.swift` | `startA: Int`, `startB: Int`, `length: Int` |
| `TilingState` | `TilingState.swift` | `markedA: [Bool]`, `markedB: [Bool]`, `totalCovered: Int` |

---

## Type4Detector (Type-4)

`struct Type4Detector: DetectionAlgorithm`

Detects semantic clones using behavioral signatures and abstract semantic graphs.

See also: [SemanticGraph](SemanticGraph.md), [BehaviorSignature](#behaviorsignature)

### Algorithm

1. **Build signed blocks**: For each code block, extract `BehaviorSignature` + `AbstractSemanticGraph`
2. **Pre-filter**: Control flow shape length ratio must be >= 30%
3. **Compute similarity**: Combined = `0.6 * graphSimilarity + 0.4 * behaviorSimilarity`
4. **Deduplicate**: Remove subsumed clones

### Properties

| Property | Type | Default |
|---|---|---|
| `semanticSimilarityThreshold` | `Double` | `80.0` |
| `minimumTokenCount` | `Int` | `50` |
| `minimumLineCount` | `Int` | `5` |

### Related Types

| Type | File | Properties |
|---|---|---|
| `IndexedBlock` | `IndexedBlock.swift` | `block: CodeBlock`, `fileIndex: Int` |
| `IndexedBlockPair` | `IndexedBlockPair.swift` | `blockA: IndexedBlock`, `blockB: IndexedBlock` |
| `SignedBlock` | `SignedBlock.swift` | `indexed`, `signature: BehaviorSignature`, `graph: AbstractSemanticGraph` |
| `Type3CandidatePair` | `Type3CandidatePair.swift` | `blockA: IndexedBlock`, `blockB: IndexedBlock` |
| `Type4CandidatePair` | `Type4CandidatePair.swift` | `blockA: SignedBlock`, `blockB: SignedBlock` |

---

## BehaviorSignature

`struct BehaviorSignature: Sendable, Equatable`

Captures the behavioral characteristics of a code block.

| Property | Type | Description |
|---|---|---|
| `controlFlowShape` | `[ControlFlowNode]` | Sequence of control flow statements |
| `dataFlowPatterns` | `[DataFlowPattern]` | Variable define/use patterns |
| `calledFunctions` | `Set<String>` | Names of called functions |
| `typeSignatures` | `Set<String>` | Type annotations used |

---

## BehaviorSignatureExtractor

`struct BehaviorSignatureExtractor: Sendable`

Extracts `BehaviorSignature` from source code using a SwiftSyntax `SyntaxVisitor`. Tracks control flow statements, function calls, variable definitions/uses, parameters, and type annotations.

| Method | Signature |
|---|---|
| `extract` | `(source: String, file: String, startLine: Int, endLine: Int) -> BehaviorSignature` |

---

## BehaviorSignatureComparer

`struct BehaviorSignatureComparer: Sendable`

Compares two `BehaviorSignature` instances with weighted components.

| Component | Weight | Method |
|---|---|---|
| Control flow | 40% | LCS similarity |
| Data flow | 30% | Bag-based Jaccard |
| Called functions | 20% | Set Jaccard |
| Type signatures | 10% | Set Jaccard |

| Method | Signature |
|---|---|
| `similarity` | `(between signatureA: BehaviorSignature, and signatureB: BehaviorSignature) -> Double` |

---

## ControlFlowNode

`enum ControlFlowNode: String, Sendable, Equatable, Hashable`

| Case |
|---|
| `ifStatement`, `guardStatement`, `switchStatement` |
| `forLoop`, `whileLoop`, `repeatLoop` |
| `doCatch` |
| `returnStatement`, `throwStatement`, `breakStatement`, `continueStatement` |

---

## DataFlowPattern

`enum DataFlowPattern: String, Sendable, Equatable, Hashable`

| Case | Description |
|---|---|
| `defineAndUse` | Variable defined and later used |
| `defineOnly` | Variable defined but never used |
| `useOnly` | Variable used but not defined in scope |
| `parameterUse` | Function parameter used in body |
