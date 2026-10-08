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
| `.typeName` | Both | Swift: names in type positions and function/constructor callees (`Int`, `Color(...)`); C-family: known Foundation types and capitalized words (`NSString`, `MyClass`) |
| `.integerLiteral` | Both | `42`, `0xFF` (C-family character literals such as `'a'` are also emitted as `.integerLiteral`) |
| `.floatingLiteral` | Both | `3.14` |
| `.stringLiteral` | Both | `"hello"` |
| `.operatorToken` | Both | `+`, `==`, `!=`, `->` |
| `.punctuation` | Both | `(`, `)`, `{`, `}`, `,`, `;`, `.`, `:` |

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

Uses the **swift-syntax** `Parser` to produce a full `SourceFileSyntax` tree. Tokens are extracted with `tokens(viewMode: .sourceAccurate)`; each `TokenSyntax` is converted to a `Token` whose line and column are taken from its position after leading trivia.

**Kind mapping:** swift-syntax keywords and `#if`/`#else`/`#elseif`/`#endif`/`#available`/`#unavailable`/`#sourceLocation` become `.keyword`; string segments become `.stringLiteral`; binary/prefix/postfix operators, `=` and `->` become `.operatorToken`; brackets, `,`, `:`, `::`, `;`, `.`, `!`, `?`, `@`, `#`, `\`, `` ` ``, `...` and `&` become `.punctuation`. Some token kinds are dropped entirely: end-of-file, string quotes and raw-string delimiters, regex literal parts, `$0`-style identifiers, `_`, shebangs, and unknown tokens.

**Type promotion:** an `identifier` token is promoted to `.typeName` when its parent node is `IdentifierTypeSyntax`, `MemberTypeSyntax`, or when it is the callee of a `FunctionCallExprSyntax` (via `DeclReferenceExprSyntax`). This covers both type annotations (`let x: Int`) and constructor/function calls (`Color(r: 0)`). For all other positions, `kind` defaults to `.identifier`.

### CTokenizer

```swift
struct CTokenizer: Sendable
func tokenize(source: String, file: String) -> [Token]
```

A manual scanner for C, C++, and Objective-C source files. The pipeline uses it for every file that does not end in `.swift`; C-family files (`.c`, `.cpp`, `.h`, `.m`, `.mm`) are only discovered when cross-language mode is enabled. `tokenize` simply drains `CTokenizerScanner.nextToken()` until it returns `nil`.

### CTokenizerScanner

```swift
struct CTokenizerScanner
init(source: String, file: String)
mutating func nextToken() -> Token?
```

Character-level scanner that tracks the current index, `line`, and `column` (both 1-based). Behavior:

- Whitespace, line comments (`//`), and block comments (`/* */`) are skipped
- Preprocessor directives (any line starting with `#`, e.g. `#import`, `#define`) are skipped entirely and produce no tokens
- `@` followed by a known Objective-C keyword (`@interface`, `@property`, `@end`, …) produces a `.keyword`; `@"..."` produces a `.stringLiteral`; any other `@` produces `.punctuation`
- String literals (`"..."`) produce `.stringLiteral` with escape sequences skipped; character literals (`'a'`) produce `.integerLiteral`
- Numbers: hex (`0x…`), decimal, fractional, and exponent forms; a `.` or exponent makes it `.floatingLiteral`. Suffixes `f`, `F`, `l`, `L`, `u`, `U` are consumed but not included in the token text
- Operators: two-character operators (`==`, `!=`, `<=`, `>=`, `&&`, `||`, `++`, `--`, `+=`, `-=`, `*=`, `/=`, `->`, `<<`, `>>`) are matched first, otherwise a single operator character
- Words are classified by `CLanguageVocabulary.classifyWord`

Message sends (`[receiver message:arg]`) and C++ `::` receive no special treatment here — they are emitted as ordinary punctuation/identifier tokens. Message-send rewriting happens in `UnifiedTokenMapper`.

### CLanguageVocabulary

```swift
enum CLanguageVocabulary
static func classifyWord(_ text: String) -> TokenKind
```

Namespace holding the C-family vocabularies used by `CTokenizerScanner`: `cKeywords`, `objcKeywords` (`nil`, `YES`, `NO`, `self`, `super`), `objcAtKeywords`, `knownTypeNames` (Foundation/CoreGraphics types such as `NSString`, `NSInteger`, `CGFloat`, `BOOL`, `id`), `operatorStartCharacters`, `punctuationCharacters`, and `twoCharOperators`.

`classifyWord` returns `.keyword` for C or Objective-C keywords, `.typeName` for known type names or any word starting with an uppercase letter, and `.identifier` otherwise.

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

Active only when `crossLanguageEnabled` is `true`, in which case it is applied to the raw tokens of every file (Swift and C-family). Maps language-specific tokens to a common vocabulary, so that clones between `.swift` and `.m` files can be detected by the same algorithm. It works in two passes:

1. **Per-token mapping**
   - Collection type names (`Array`, `NSArray`, `NSMutableArray`, `Dictionary`, `NSDictionary`, `NSMutableDictionary`, `Set`, `NSSet`, `NSMutableSet`, `NSOrderedSet`, `NSMutableOrderedSet`) → `.identifier` `$COLLECTION_TYPE`
   - Type names: `NSString`/`NSMutableString` → `String`, `NSInteger`/`NSUInteger`/`CGFloat` → `Int`, `NSObject`/`id` → `AnyObject`, `BOOL` → `Bool`
   - Keywords: `YES` → `true`, `NO` → `false`, `@interface`/`@implementation` → `class`, `@property` → `var`
2. **Pattern normalization**
   - Objective-C message send with arguments (`[recv sel: …]`) → `$CALL` followed by the argument tokens (`:` and the closing `]` dropped)
   - Objective-C message send without arguments (`[recv sel]`) → `$ACCESS`
   - `identifier (` → `$CALL (`
   - `identifier . identifier` not followed by `(` → `$ACCESS`

Applied **before** suppression filtering and `TokenNormalizer` in the pipeline.

---

## SuppressionScanner

```swift
struct SuppressionScanner: Sendable
init(tag: String = "swiftcpd:ignore")
func suppressedLines(in source: String) -> Set<Int>
```

Scans raw source text for the suppression tag and returns the set of line numbers (1-based) whose tokens should be dropped.

A line is a suppression directive when, after leading whitespace, it starts with `//` or `/*` followed (after optional whitespace) by the tag. The directive always applies to the **next non-blank line**:

| Next non-blank line | Effect |
|---|---|
| Contains `{` | That line through the line where the braces balance back to zero is suppressed (whole block) |
| Anything else | Only that line is suppressed |

The directive line itself is not added to the set. Any `Token` whose `location.line` is in the suppressed set is removed before normalization and detection. The suppression tag is configurable via `--suppression-tag` (or `inlineSuppressionTag` in YAML).

---

← [File Discovery](02-file-discovery.md) | Next: [Pipeline →](04-pipeline.md)
