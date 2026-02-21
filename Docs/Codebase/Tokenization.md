# Tokenization

Converts source code into token sequences. Supports Swift (via SwiftSyntax) and C-family languages (hand-written scanner). Includes normalization and cross-language mapping.

## Files

- `Sources/SwiftCPD/Tokenization/Token.swift`
- `Sources/SwiftCPD/Tokenization/TokenKind.swift`
- `Sources/SwiftCPD/Tokenization/SourceLocation.swift`
- `Sources/SwiftCPD/Tokenization/SwiftTokenizer.swift`
- `Sources/SwiftCPD/Tokenization/CTokenizer.swift`
- `Sources/SwiftCPD/Tokenization/CTokenizerScanner.swift`
- `Sources/SwiftCPD/Tokenization/CLanguageVocabulary.swift`
- `Sources/SwiftCPD/Tokenization/TokenNormalizer.swift`
- `Sources/SwiftCPD/Tokenization/UnifiedTokenMapper.swift`

---

## Token

`struct Token: Sendable, Equatable, Hashable, Codable`

A single token extracted from source code.

| Property | Type | Description |
|---|---|---|
| `kind` | `TokenKind` | Category of the token |
| `text` | `String` | Original text of the token |
| `location` | `SourceLocation` | File, line, and column |

---

## TokenKind

`enum TokenKind: String, Sendable, Equatable, Hashable, Codable`

| Case | Example |
|---|---|
| `keyword` | `func`, `if`, `let` |
| `identifier` | `myVariable`, `doSomething` |
| `typeName` | `String`, `Int`, `MyClass` |
| `integerLiteral` | `42`, `0xFF` |
| `floatingLiteral` | `3.14` |
| `stringLiteral` | `"hello"` |
| `operatorToken` | `+`, `==`, `->` |
| `punctuation` | `{`, `}`, `(`, `)`, `;` |

---

## SourceLocation

`struct SourceLocation: Sendable, Equatable, Hashable, Codable`

| Property | Type |
|---|---|
| `file` | `String` |
| `line` | `Int` |
| `column` | `Int` |

---

## SwiftTokenizer

`struct SwiftTokenizer: Sendable`

Tokenizes Swift source code using SwiftParser/SwiftSyntax. Classifies identifiers as `typeName` or `identifier` based on syntax tree context (e.g., type annotations, inheritance clauses).

| Method | Signature |
|---|---|
| `tokenize` | `(source: String, file: String) -> [Token]` |

---

## CTokenizer

`struct CTokenizer: Sendable`

Wrapper that uses `CTokenizerScanner` to tokenize C-family source code.

| Method | Signature |
|---|---|
| `tokenize` | `(source: String, file: String) -> [Token]` |

---

## CTokenizerScanner

`struct CTokenizerScanner`

Hand-written lexer for C, C++, Objective-C, and Objective-C++. Processes source code character by character.

### Capabilities

- Skips whitespace, line comments (`//`), block comments (`/* */`)
- Skips preprocessor directives (`#include`, `#define`, etc.)
- Scans string literals (including `@"string"` for Objective-C)
- Scans character literals (`'c'`)
- Scans integer (decimal, hex) and floating-point numbers
- Recognizes C/C++ and Objective-C keywords
- Recognizes Objective-C at-keywords (`@interface`, `@property`, etc.)
- Recognizes operators and punctuation

| Method | Signature | Description |
|---|---|---|
| `init` | `(source: String, file: String)` | Initializes scanner at start of source |
| `nextToken` | `() -> Token?` | Returns next token or `nil` at end |

---

## CLanguageVocabulary

`enum CLanguageVocabulary`

Static sets of C/Objective-C language elements used by `CTokenizerScanner`.

| Property | Type | Content |
|---|---|---|
| `cKeywords` | `Set<String>` | `if`, `while`, `for`, `return`, etc. |
| `objcKeywords` | `Set<String>` | `self`, `super`, `nil`, `YES`, `NO` |
| `objcAtKeywords` | `Set<String>` | `@interface`, `@property`, `@implementation`, etc. |
| `knownTypeNames` | `Set<String>` | `NSString`, `NSArray`, `BOOL`, `NSInteger`, etc. |
| `operatorStartCharacters` | `Set<Character>` | `+`, `-`, `*`, `/`, `=`, `<`, `>`, etc. |
| `punctuationCharacters` | `Set<Character>` | `{`, `}`, `(`, `)`, `[`, `]`, `;`, `,`, etc. |
| `twoCharOperators` | `Set<String>` | `==`, `!=`, `<=`, `>=`, `&&`, `||`, etc. |

| Method | Signature | Description |
|---|---|---|
| `classifyWord` | `(_ text: String) -> TokenKind` | Classifies a word as keyword, typeName, or identifier |

---

## TokenNormalizer

`struct TokenNormalizer: Sendable`

Replaces variable parts of tokens with placeholders, enabling structural comparison regardless of naming.

| Original Kind | Placeholder |
|---|---|
| `identifier` | `$ID` |
| `typeName` | `$TYPE` |
| `integerLiteral` | `$NUM` |
| `floatingLiteral` | `$NUM` |
| `stringLiteral` | `$STR` |
| `keyword` | (unchanged) |
| `operatorToken` | (unchanged) |
| `punctuation` | (unchanged) |

| Method | Signature |
|---|---|
| `normalize` | `(_ tokens: [Token]) -> [Token]` |

---

## UnifiedTokenMapper

`struct UnifiedTokenMapper: Sendable`

Maps C/Objective-C tokens to Swift equivalents for cross-language [detection](Detection.md). Only active when `--cross-language` is enabled.

### Type Mappings

`NSString` -> `String`, `BOOL` -> `Bool`, `NSInteger` -> `Int`, `NSArray` -> `Array`, etc.

### Keyword Mappings

`YES` -> `true`, `NO` -> `false`, `@property` -> `var`, `@interface` -> `class`, etc.

### Pattern Normalizations

| Objective-C Pattern | Normalized |
|---|---|
| `[obj method:arg]` (message send) | `$CALL` |
| `obj.property` (property access) | `$ACCESS` |
| `id(args)` (function call) | `$CALL` |

| Method | Signature |
|---|---|
| `map` | `(_ tokens: [Token]) -> [Token]` |
