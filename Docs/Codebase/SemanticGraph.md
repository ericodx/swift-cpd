# SemanticGraph

Abstract Semantic Graph (ASG) used by the [Type-4 detector](Detection.md#type4detector-type-4) to compare code semantics.

## Files

- `Sources/SwiftCPD/Detection/SemanticGraph/AbstractSemanticGraph.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/SemanticNode.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/SemanticNodeKind.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/SemanticEdge.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/SemanticEdgeKind.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/SemanticNormalizer.swift`
- `Sources/SwiftCPD/Detection/SemanticGraph/ASGComparer.swift`

---

## AbstractSemanticGraph

`struct AbstractSemanticGraph: Sendable, Equatable`

A directed graph representing the semantic structure of a code block.

| Property | Type | Description |
|---|---|---|
| `nodes` | `[SemanticNode]` | Semantic operations in the code |
| `edges` | `[SemanticEdge]` | Relationships between operations |

| Static Property | Description |
|---|---|
| `empty` | An empty graph with no nodes or edges |

---

## SemanticNode

`struct SemanticNode: Sendable, Equatable, Hashable`

| Property | Type |
|---|---|
| `id` | `Int` |
| `kind` | `SemanticNodeKind` |

---

## SemanticNodeKind

`enum SemanticNodeKind: String, Sendable, Equatable, Hashable, CaseIterable`

| Case | Represents |
|---|---|
| `assignment` | Variable assignment (`let x = ...`) |
| `functionCall` | Function or method call |
| `returnValue` | Return statement |
| `conditional` | `if` / `switch` |
| `loop` | `for` / `while` / `repeat` |
| `guardExit` | `guard` with early exit |
| `errorHandling` | `do-catch` / `throw` |
| `collectionOperation` | `map`, `filter`, `reduce`, `forEach`, etc. |
| `optionalUnwrap` | Optional binding (`if let`, `guard let`) |
| `parameterInput` | Function parameter |
| `literalValue` | Literal value in binding |

---

## SemanticEdge

`struct SemanticEdge: Sendable, Equatable, Hashable`

| Property | Type | Description |
|---|---|---|
| `from` | `Int` | Source node ID |
| `to` | `Int` | Target node ID |
| `kind` | `SemanticEdgeKind` | Type of relationship |

---

## SemanticEdgeKind

`enum SemanticEdgeKind: String, Sendable, Equatable, Hashable`

| Case | Description |
|---|---|
| `controlFlow` | Sequential execution order |
| `dataFlow` | Data dependency (variable defined then used) |

---

## SemanticNormalizer

`struct SemanticNormalizer: Sendable`

Builds an `AbstractSemanticGraph` from Swift source code using a SwiftSyntax `SyntaxVisitor`.

| Method | Signature |
|---|---|
| `normalize` | `(source: String, file: String, startLine: Int, endLine: Int) -> AbstractSemanticGraph` |

### Graph Construction

The visitor walks the AST within the specified line range and:

- Creates nodes for assignments, function calls, conditionals, loops, guards, error handling, etc.
- Adds **control flow edges** between sequential nodes automatically
- Adds **data flow edges** when a variable defined in one node is used in another
- Detects collection operations (`map`, `filter`, `reduce`, `forEach`, `compactMap`, `flatMap`, `sorted`, `contains`)
- Detects optional unwrapping in `if let` / `guard let` conditions
- Detects literal values in bindings

---

## ASGComparer

`struct ASGComparer: Sendable`

Compares two `AbstractSemanticGraph` instances with weighted components.

| Component | Weight | Method |
|---|---|---|
| Node similarity | 60% | Bag-based Jaccard on `SemanticNodeKind` frequencies |
| Edge similarity | 40% | LCS on `SemanticEdgeKind` sequences |

| Method | Signature |
|---|---|
| `similarity` | `(between graphA: AbstractSemanticGraph, and graphB: AbstractSemanticGraph) -> Double` |
