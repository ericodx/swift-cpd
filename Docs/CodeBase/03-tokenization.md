# Tokenization

← [File Discovery](02-file-discovery.md) | Next: [Pipeline →](04-pipeline.md)

---

## Core Types

### Token

```swift
struct Token: Sendable, Equatable, Hashable, Codable
```

The atomic unit of analysis. Every token carries its semantic classification, original text, and precise source position.

```swift
let kind:     TokenKind
let text:     String
let location: SourceLocation
```

`Token` is `Codable` because it is persisted in the file cache.

### TokenKind

```swift
enum TokenKind: String, Sendable, Equatable, Hashable, Codable
```

| Case | Produced by | Example |
|---|---|---|
| `.keyword` | Both tokenizers | `func`, `var`, `let`, `if`, `return` |
| `.identifier` | Both | variable and function names |
| `.typeName` | `SwiftTokenizer` | names in type positions and function/constructor callees (`Int`, `Color(...)`) |
| `.integerLiteral` | Both | `42`, `0xFF` |
| `.floatingLiteral` | Both | `3.14` |
| `.stringLiteral` | Both | `"hello"` |
| `.operatorToken` | Both | `+`, `==`, `!=`, `->` |
| `.punctuation` | Both | `(`, `)`, `{`, `}`, `,`, `;`, `::` |
| `.colonColon` | `SwiftTokenizer` | `::` C++ namespace qualifier (swift-syntax 603+) |

`typeName` is distinct from `identifier` so that `TokenNormalizer` can preserve type and callee names while normalizing regular identifiers. This prevents false positives between structurally similar code that uses different types (e.g., `Color(r:g:b:)` vs `GridToken(columns:gutter:margin:)`).

### SourceLocation

```swift
struct SourceLocation: Sendable, Equatable, Hashable, Codable
```

```swift
let file:   String   // absolute path
let line:   Int      // 1-based
let column: Int      // 1-based
```

---

## Tokenizers

### SwiftTokenizer

```swift
struct SwiftTokenizer: Sendable
func tokenize(source: String, file: String) -> [Token]
```

Uses the **swift-syntax** `Parser` to produce a full `SourceFileSyntax` tree. Tokens are extracted by walking the tree; each `TokenSyntax` node is converted to a `Token` with its exact line and column.

**Type promotion:** an `identifier` token is promoted to `.typeName` when its parent node is `IdentifierTypeSyntax`, `MemberTypeSyntax`, or when it is the callee of a `FunctionCallExprSyntax` (via `DeclReferenceExprSyntax`). This covers both type annotations (`let x: Int`) and constructor/function calls (`Color(r: 0)`). For all other positions, `kind` defaults to `.identifier`.

### CTokenizer

```swift
struct CTokenizer: Sendable
func tokenize(source: String, file: String) -> [Token]
```

A manual state-machine scanner for C, C++, and Objective-C source files (`.c`, `.cpp`, `.h`, `.m`, `.mm`). Handles:

- C preprocessor directives (`#import`, `#define`, `#pragma`)
- Objective-C message sends (`[receiver message:arg]`)
- C++ templates and namespace qualifiers
- Block comments (`/* */`) and line comments (`//`)
- Multi-line string literals

Uses `CTokenizerScanner` as the underlying character-level scanner.

---

## Token Processing

### TokenNormalizer

```swift
struct TokenNormalizer: Sendable
func normalize(_ tokens: [Token]) -> [Token]
```

Returns a new token list where regular identifiers and literals are replaced with language-agnostic placeholders. Type names, callee names, keywords, operators, and punctuation are preserved as-is.

| `TokenKind` | Replacement text |
|---|---|
| `.identifier` | `$ID` |
| `.typeName` | *(preserved)* |
| `.integerLiteral` | `$NUM` |
| `.floatingLiteral` | `$NUM` |
| `.stringLiteral` | `$STR` |

After normalization, `var x = 5` and `var y = 10` produce identical token sequences (`var $ID = $NUM`), enabling Type 2 detection. However, `Color(r: 0)` and `GridToken(columns: 2)` remain distinct because callee names are preserved.

### UnifiedTokenMapper

```swift
struct UnifiedTokenMapper: Sendable
func map(_ tokens: [Token]) -> [Token]
```

Active only when `crossLanguageEnabled` is `true`. Maps language-specific token kinds from both Swift and C-family tokenizers to a common vocabulary, so that clones between `.swift` and `.m` files can be detected by the same algorithm.

Applied **before** `TokenNormalizer` in the pipeline.

---

## SuppressionScanner

```swift
struct SuppressionScanner: Sendable
init(tag: String = "swiftcpd:ignore")
func suppressedLines(in source: String) -> Set<Int>
```

Scans raw source text for the suppression tag and returns the set of line numbers (1-based) that should be excluded from tokenization.

**Two suppression modes:**

| Placement | Effect |
|---|---|
| Comment before a `{...}` block | All lines within the block are suppressed |
| Comment on any other line | Only that line is suppressed |

Any `Token` whose `location.line` is in the suppressed set is removed before normalization and detection. The suppression tag is configurable via `--suppression-tag`.

---

← [File Discovery](02-file-discovery.md) | Next: [Pipeline →](04-pipeline.md)
