# Detection — Core Types

← [Pipeline](04-pipeline.md) | Next: [Detection — Type 1 & 2 →](06-detection-type12.md)

---

## Protocol

### DetectionAlgorithm

```swift
protocol DetectionAlgorithm: Sendable
```

The single abstraction that all three detectors conform to.

```swift
var supportedCloneTypes: Set<CloneType> { get }
func detect(files: [FileTokens]) -> [CloneGroup]
```

`detect` is a pure synchronous function. All detectors are value types (`struct`), so they require no synchronization and can be composed or swapped freely.

---

## Clone Types

### CloneType

```swift
enum CloneType: Int, Sendable, Equatable, Hashable, CaseIterable
```

| Case | Value | Description |
|---|---|---|
| `.type1` | `1` | Exact copy (after normalization) |
| `.type2` | `2` | Parameterized — same structure, different names/literals |
| `.type3` | `3` | Near-miss — additions, deletions, or rearrangement |
| `.type4` | `4` | Semantic — different implementation, same behavior |

The `rawValue` is the integer used in YAML configuration (`enabledCloneTypes: [1, 2, 3, 4]`).

---

## Result Types

### CloneGroup

```swift
struct CloneGroup: Sendable, Equatable, Hashable
```

One detected clone pair and its metadata.

```swift
let type:        CloneType
let tokenCount:  Int
let lineCount:   Int
let similarity:  Double    // always 100.0 for Type 1/2; percentage for Type 3/4
let fragments:   [CloneFragment]  // exactly two entries

var isStructural: Bool { type == .type3 || type == .type4 }
var isSameFile:   Bool  // true if all fragments are in the same file (false when empty)
```

`CloneGroup` also has a failable initializer (in an `extension`) used by Type 3 and Type 4 detectors to apply the `minimumLineCount` filter during construction:

```swift
init?(
    type: CloneType,
    pair: IndexedBlockPair,
    files: [FileTokens],
    similarity: Double,
    minimumLineCount: Int
)
```

It builds both fragments with `CloneFragment(_:files:)`, sets `lineCount` to the larger fragment line span and returns `nil` if that is below `minimumLineCount`, sets `tokenCount` to the larger block token span, and converts `similarity` from a `0...1` fraction to a percentage rounded to one decimal place (`(similarity * 1000).rounded() / 10`).

### CloneFragment

```swift
struct CloneFragment: Sendable, Equatable, Hashable
```

Source location of one side of a clone.

```swift
let file:        String
let startLine:   Int
let endLine:     Int
let startColumn: Int
let endColumn:   Int
```

Two convenience initializers (in an `extension`, to preserve the memberwise initializer):

```swift
// From raw token indices
init(file: String, tokens: [Token], startIndex: Int, endIndex: Int)

// From an IndexedBlock (uses files[indexed.fileIndex].tokens)
init(_ indexed: IndexedBlock, files: [FileTokens])
```

Lines and `startColumn` come from the first and last tokens; `endColumn` is the last token's column plus its text length.

---

## Input Type

### FileTokens

```swift
struct FileTokens: Sendable
```

The per-file input to every detector, produced by `AnalysisPipeline` (from a fresh tokenization or a cache hit).

```swift
let file:             String
let source:           String   // full source text, re-parsed by block-based detectors
let tokens:           [Token]  // raw tokens (after cross-language mapping and suppression)
let normalizedTokens: [Token]  // tokens after TokenNormalizer
```

---

## Block Extraction

Block-based detectors (Type 3, Type 4) operate on syntactic blocks rather than raw token streams. The following types form the extraction pipeline.

```mermaid
flowchart TD
    FT["FileTokens (source + tokens)"] --> BE["BlockExtractor"]
    BE --> BV["BlockVisitor (swift-syntax walk)"]
    BV --> LR["lineRanges [(start, end)]"]
    LR --> TI["mapToTokenRange (binary search + scan)"]
    TI --> CB["CodeBlock list"]
    CB --> filter["filter tokenCount ≥ minimumTokenCount"]
    filter --> IB["IndexedBlock (block + fileIndex)"]
    IB --> result["[IndexedBlock]"]
```

### BlockExtraction

```swift
enum BlockExtraction
static func extractValidBlocks(files: [FileTokens], minimumTokenCount: Int) -> [IndexedBlock]
```

Namespace that coordinates `BlockExtractor` across all files. Blocks are extracted against each file's `normalizedTokens`; blocks whose token span (`endTokenIndex - startTokenIndex + 1`) is below `minimumTokenCount` are dropped, and the rest are wrapped in `IndexedBlock` with their position in `files`.

### BlockExtractor

```swift
struct BlockExtractor: Sendable
func extract(source: String, file: String, tokens: [Token]) -> [CodeBlock]
```

Parses `source` with swift-syntax, runs `BlockVisitor` to get block line ranges, then maps each range to token indices: a binary search finds the first token at or after `startLine`, then a linear scan extends to the last token on or before `endLine`. Ranges that contain no tokens are dropped.

### BlockVisitor

```swift
final class BlockVisitor: SyntaxVisitor
```

A swift-syntax `SyntaxVisitor` (source-accurate view) that records the line ranges of all extractable block constructs:

- `FunctionDeclSyntax` — body of free functions and methods
- `InitializerDeclSyntax` — `init` bodies
- `AccessorDeclSyntax` — `get`, `set`, `willSet`, `didSet` bodies
- `ClosureExprSyntax` — the whole closure expression

Declarations without a body are skipped. The visitor always continues into children, so nested blocks are recorded too.

```swift
init(converter: SourceLocationConverter)

let converter:  SourceLocationConverter
var lineRanges: [(startLine: Int, endLine: Int)]
```

### RangedSyntaxVisitor

```swift
class RangedSyntaxVisitor: SyntaxVisitor
```

Base class for `BehaviorSignatureExtractor` and `SemanticNormalizer`. Parses `source` at construction time and provides range-gating helpers.

```swift
init(source: String, file: String, startLine: Int, endLine: Int)

let sourceFile:  SourceFileSyntax
let converter:   SourceLocationConverter
let startLine:   Int
let endLine:     Int

func run()                                       // calls walk on sourceFile
func isInRange(_ node: some SyntaxProtocol) -> Bool
```

`isInRange` checks that the node's start line falls within `[startLine, endLine]`. Visitor overrides call this before processing any node.

### CodeBlock

```swift
struct CodeBlock: Sendable, Equatable
let file:            String
let startLine:       Int
let endLine:         Int
let startTokenIndex: Int
let endTokenIndex:   Int
```

### IndexedBlock

```swift
struct IndexedBlock: Sendable
let block:     CodeBlock
let fileIndex: Int   // index into the [FileTokens] array
```

### IndexedBlockPair

```swift
struct IndexedBlockPair: Sendable
let blockA: IndexedBlock
let blockB: IndexedBlock
```

Used to construct `CloneGroup` from a matched pair in Type 3 and Type 4 detectors.

---

## CloneGroupDeduplicator

```swift
enum CloneGroupDeduplicator
static func deduplicate(_ clones: [CloneGroup]) -> [CloneGroup]
```

Removes clones that are covered by a clone kept earlier in the list (order-dependent, first one wins). A clone is subsumed by another when, pairing fragments positionally, each fragment is in the same file and its `startLine...endLine` lies within the other's line range. Used by `Type3Detector` and `Type4Detector` after scoring.

---

← [Pipeline](04-pipeline.md) | Next: [Detection — Type 1 & 2 →](06-detection-type12.md)
