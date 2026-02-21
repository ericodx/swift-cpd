# Suppression

Inline suppression of clone detection using source code comments.

## Files

- `Sources/SwiftCPD/Suppression/SuppressionScanner.swift`

---

## SuppressionScanner

`struct SuppressionScanner: Sendable`

Scans source code for suppression tags and returns the set of line numbers that should be excluded from detection.

**Default tag:** `// swiftcpd:ignore`

### Properties

| Property | Type | Default |
|---|---|---|
| `tag` | `String` | `"swiftcpd:ignore"` |

### Methods

| Method | Signature | Description |
|---|---|---|
| `init` | `(tag: String)` | Creates scanner with custom tag |
| `suppressedLines` | `(in source: String) -> Set<Int>` | Returns line numbers to suppress |

### Suppression Rules

1. When the tag is found in a comment, the **next content line** is suppressed
2. If that content line contains `{`, the **entire block** until the matching `}` is suppressed (brace counting)
3. Blank lines between the tag and content are skipped

### Example

```swift
// swiftcpd:ignore
func duplicatedFunction() {
    // this entire function body is suppressed
    let x = 1
    let y = 2
}
```

All lines from `func` through the closing `}` are added to the suppressed set. Tokens on these lines are excluded from [detection](Detection.md).
