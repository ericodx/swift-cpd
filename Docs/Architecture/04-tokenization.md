# Tokenization

← [Detection](03-detection.md) | Next: [Supporting Systems →](05-supporting-systems.md)

---

## Responsibilities

The tokenization layer transforms raw source text into the `FileTokens` structure consumed by all detectors. It consists of three steps: tokenization, normalization, and (optionally) unified mapping for cross-language analysis.

```mermaid
flowchart TD
    SRC[Source file text]
    SRC --> SW{File extension?}
    SW -- .swift --> ST[SwiftTokenizer<br/>swift-syntax Parser]
    SW -- .m .mm .h .c .cpp --> CT[CTokenizer<br/>manual scanner]
    ST --> TK[Token list]
    CT --> TK
    TK --> SS[SuppressionScanner<br/>remove suppressed lines]
    SS --> UM{Cross-language?}
    UM -- yes --> MP[UnifiedTokenMapper<br/>map to common token kinds]
    UM -- no --> NM[TokenNormalizer<br/>replace names with placeholders]
    MP --> NM
    NM --> FT["FileTokens<br/>(tokens · normalizedTokens)"]
```

---

## Token

Every token carries three fields:

| Field | Type | Description |
|---|---|---|
| `kind` | `TokenKind` | Semantic classification |
| `text` | `String` | Exact source text |
| `location` | `SourceLocation` | file · line · column |

### TokenKind

```
keyword           — func, var, let, if, return, …
identifier        — variable and function names
typeName          — names in type positions
integerLiteral    — 42, 0xFF
floatingLiteral   — 3.14
stringLiteral     — "hello"
operatorToken     — +, -, ==, !=, …
punctuation       — (, ), {, }, [, ], ,, ;, ::
colonColon        — :: (C++ namespace qualifier, swift-syntax 603+)
```

---

## SwiftTokenizer

Uses the **swift-syntax** `Parser` to produce a full syntax tree from Swift source. Tokens are extracted from the tree walk and classified based on their syntactic role:

- An `identifier` token whose parent node is `IdentifierTypeSyntax` or `MemberTypeSyntax` is promoted to `typeName`.
- An `identifier` token whose parent is a `DeclReferenceExprSyntax` that is the callee of a `FunctionCallExprSyntax` is also promoted to `typeName`. This covers constructor and function call names (e.g., `Color(...)`, `GridToken(...)`).
- All other structural positions default to `identifier`.

This classification allows `TokenNormalizer` to preserve type and callee names while replacing regular identifiers, improving the precision of Type 2 matching and reducing false positives between structurally similar but semantically unrelated code.

---

## CTokenizer

A manual state-machine scanner for C, Objective-C, and C++ sources (`.m`, `.mm`, `.h`, `.c`, `.cpp`). It handles:

- C preprocessor directives (`#import`, `#define`)
- Objective-C message sends (`[receiver message]`)
- C++ templates and namespaces
- Multi-line strings and block comments

---

## TokenNormalizer

Replaces token text with language-agnostic placeholders:

| Original | Placeholder | Applies to |
|---|---|---|
| Any identifier | `$ID` | `identifier` |
| Any integer literal | `$NUM` | `integerLiteral` |
| Any float literal | `$NUM` | `floatingLiteral` |
| Any string literal | `$STR` | `stringLiteral` |

Type names, function/constructor callee names, keywords, operators, and punctuation are preserved as-is. This means `Color(r: 0)` and `GridToken(columns: 2)` produce different normalized sequences, preventing false positives between code that shares structural patterns but uses different types.

After normalization, `var x = 5` and `var y = 10` produce the same token sequence: `var $ID = $NUM`. This is what enables Type 2 detection.

---

## UnifiedTokenMapper

When `--cross-language` is enabled, both Swift and C-family tokens are mapped to a common vocabulary before normalization. This allows the detectors to find clones across language boundaries, such as a Swift class and its Objective-C counterpart.

---

## SuppressionScanner

Scans source text for the suppression tag (default `swiftcpd:ignore`) and returns the set of line numbers that should be excluded from analysis.

**Block suppression:** the tag on the line immediately before a `{...}` block suppresses all lines within that block.

**Line suppression:** the tag on any other line suppresses only that line.

Tokens whose `location.line` falls in the suppressed set are removed before normalization, so they are invisible to all detectors.

---

← [Detection](03-detection.md) | Next: [Supporting Systems →](05-supporting-systems.md)
