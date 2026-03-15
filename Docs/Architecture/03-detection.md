# Clone Detection

← [Pipeline](02-pipeline.md) | Next: [Tokenization →](04-tokenization.md)

---

## Clone Types

```mermaid
flowchart TD
    A[Two code fragments] --> B{Identical after<br/>normalization?}
    B -- yes --> C{Identical in<br/>raw source?}
    C -- yes --> T1[Type 1 — Exact clone]
    C -- no --> T2[Type 2 — Parameterized clone<br/>same structure, different names/literals]
    B -- no --> D{High token<br/>overlap?}
    D -- yes --> T3[Type 3 — Near-miss clone<br/>additions, deletions, rearrangement]
    D -- no --> E{Semantically<br/>equivalent?}
    E -- yes --> T4[Type 4 — Semantic clone<br/>different implementation, same behavior]
    E -- no --> N[Not a clone]
```

All detectors implement the `DetectionAlgorithm` protocol and receive the same `[FileTokens]` input. Their output is a list of `CloneGroup` values.

```
CloneGroup
├── type        — CloneType (1–4)
├── tokenCount  — length in tokens
├── lineCount   — length in lines
├── similarity  — 100.0 for Type 1/2, percentage for Type 3/4
└── fragments   — [CloneFragment] (exactly two per group)

CloneFragment
├── file
├── startLine · endLine
└── startColumn · endColumn
```

---

## Type 1 & 2 — CloneDetector

`CloneDetector` detects both exact and parameterized clones in a single pass over **normalized** tokens. Classification happens at the end by comparing raw tokens.

```mermaid
flowchart TD
    A[normalizedTokens per file] --> B

    subgraph B["① Find candidates — Rolling hash"]
        B1[Slide window of minimumTokenCount] --> B2[Compute hash per position]
        B2 --> B3[Group positions by hash]
        B3 --> B4[Keep groups with 2+ entries]
    end

    B --> C

    subgraph C["② Verify — Exact token comparison"]
        C1[For each candidate group] --> C2[Compare token text in window]
        C2 --> C3[Discard overlapping pairs<br/>distance < minimumTokenCount]
    end

    C --> D

    subgraph D["③ Expand regions"]
        D1[Extend match backwards] --> D2[Extend match forwards]
    end

    D --> E

    subgraph E["④ Classify"]
        E1{Raw tokens<br/>identical?}
        E1 -- yes --> E2[Type 1]
        E1 -- no --> E3[Type 2]
    end

    E --> F["⑤ Deduplicate — remove subsumed pairs"]
    F --> G["⑥ Filter by minimumLineCount"]
```

**Rolling hash:** polynomial hash with base 31 and modulus 10⁹+7. Updating the hash when sliding the window is O(1) per position, making the overall complexity O(n) per file.

---

## Type 3 — Near-Miss Clones

`Type3Detector` operates on **syntactic blocks** (functions, closures, control statements) rather than raw token streams. It uses a two-phase approach to keep the quadratic comparison cost manageable.

```mermaid
flowchart TD
    A[FileTokens] --> B["BlockExtraction<br/>extract syntactic blocks ≥ minimumTokenCount"]
    B --> C

    subgraph C["① Pre-filter — Jaccard similarity"]
        C1[Build BlockFingerprint<br/>token frequency map per block]
        C1 --> C2["Compute Bag-Jaccard<br/>|A ∩ B| / |A ∪ B|"]
        C2 --> C3["Keep pairs ≥ candidateFilterThreshold (30%)"]
    end

    C --> D

    subgraph D["② Score — Greedy String Tiling"]
        D1[Find longest matching tile ≥ type3TileSize] --> D2[Mark tiles as used]
        D2 --> D3[Repeat until no more tiles]
        D3 --> D4["similarity = 2 × covered / (|A| + |B|)"]
    end

    D --> E["Keep pairs ≥ type3Similarity (70%)"]
    E --> F[CloneGroupDeduplicator]
```

**Greedy String Tiling (GST):** finds the largest non-overlapping matching substrings between two token sequences. It is order-sensitive (unlike Jaccard), catching cases where blocks share a high proportion of common code but with some statements added, removed, or reordered.

---

## Type 4 — Semantic Clones

`Type4Detector` compares code behavior rather than token sequences. Each block is analyzed to produce two complementary representations.

```mermaid
flowchart TD
    A[FileTokens] --> B["BlockExtraction<br/>syntactic blocks ≥ minimumTokenCount"]
    B --> C

    subgraph C["Build signed blocks (per block)"]
        direction TB
        C1["BehaviorSignatureExtractor<br/>AST visitor"]
        C2["SemanticNormalizer<br/>AST visitor → AbstractSemanticGraph"]
        C1 --> SIG["BehaviorSignature<br/>control flow shape · data flow patterns<br/>called functions · type signatures"]
        C2 --> ASG["AbstractSemanticGraph<br/>nodes: conditional · loop · return · ...<br/>edges: controlFlow · dataFlow"]
    end

    C --> D

    subgraph D["① Pre-filter — control flow shape"]
        D1["ratio = min(|shapeA|, |shapeB|) / max(...)"]
        D1 --> D2["Keep pairs with ratio ≥ 0.3"]
    end

    D --> E

    subgraph E["② Score — combined similarity"]
        E1["BehaviorSignatureComparer<br/>compare signatures"]
        E2["ASGComparer<br/>compare semantic graphs"]
        E1 --> E3["combined = 0.6 × graph + 0.4 × behavior"]
        E2 --> E3
    end

    E --> F["Keep pairs ≥ type4Similarity (80%)"]
    F --> G[CloneGroupDeduplicator]
```

### BehaviorSignature

Captures observable program behavior without regard to syntax:

- **Control flow shape** — ordered sequence of statement kinds (`if`, `guard`, `for`, `while`, `switch`, `do-catch`, `return`, `throw`, …)
- **Data flow patterns** — how variables are defined and used (`defineAndUse`, `defineOnly`, `parameterUse`, `useOnly`)
- **Called functions** — set of function names invoked
- **Type signatures** — type annotations referenced

### AbstractSemanticGraph (ASG)

A graph representation of control and data flow:

| Node kind | Meaning |
|---|---|
| `conditional` | `if`, `guard`, `switch` |
| `loop` | `for`, `while`, `repeat`, `forEach` |
| `returnValue` | `return` with value |
| `guardExit` | `guard-else-return/throw` |
| `optionalUnwrap` | `if let`, `guard let` |
| `errorHandling` | `do-catch`, `throw` |
| `collectionOperation` | `map`, `filter`, `reduce`, … |
| `assignment` | variable binding |
| `literalValue` | constant literal |
| `functionCall` | call expression |
| `parameterInput` | function parameter |

Edges carry a kind: `controlFlow` (sequential execution) or `dataFlow` (variable dependency).

---

← [Pipeline](02-pipeline.md) | Next: [Tokenization →](04-tokenization.md)
