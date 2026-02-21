# FileDiscovery

Recursively discovers source files in given paths, applying exclusion patterns.

## Files

- `Sources/SwiftCPD/FileDiscovery/SourceFileDiscovery.swift`
- `Sources/SwiftCPD/FileDiscovery/FileDiscoveryError.swift`
- `Sources/SwiftCPD/FileDiscovery/GlobMatcher.swift`
- `Sources/SwiftCPD/FileDiscovery/CompiledPattern.swift`
- `Sources/SwiftCPD/FileDiscovery/SwiftFileDiscovery.swift`

---

## SourceFileDiscovery

`struct SourceFileDiscovery: Sendable`

The primary file discovery component. Finds Swift files and optionally C-family files when cross-language mode is enabled.

### Supported Extensions

| Language | Extensions |
|---|---|
| Swift | `.swift` |
| C-family (cross-language) | `.m`, `.mm`, `.h`, `.c`, `.cpp` |

### Excluded Directories

`.build`, `.git`, `DerivedData`, `Pods`, `Carthage`, `SourcePackages`

Additional exclusions can be configured via `--exclude` glob patterns.

### Properties

| Property | Type | Description |
|---|---|---|
| `crossLanguageEnabled` | `Bool` | Include C-family files |
| `globMatcher` | `GlobMatcher` | User-defined exclusion patterns |

### Methods

| Method | Signature |
|---|---|
| `init` | `(crossLanguageEnabled: Bool, excludePatterns: [String])` |
| `findSourceFiles` | `(in paths: [String]) throws -> [String]` |

### FileDiscoveryError

`Sources/SwiftCPD/FileDiscovery/FileDiscoveryError.swift`

`enum FileDiscoveryError: Error, Sendable, Equatable`

| Case | Description |
|---|---|
| `pathDoesNotExist(String)` | The given path does not exist on disk |

---

## GlobMatcher

`struct GlobMatcher: Sendable`

Converts glob patterns to regular expressions and matches file paths. Supports `*`, `**`, `?`, and basename-only patterns (patterns without `/`).

| Method | Signature | Description |
|---|---|---|
| `init` | `(patterns: [String])` | Compiles glob patterns into regex |
| `matches` | `(_ filePath: String) -> Bool` | Tests if a file path matches any pattern |

---

## SwiftFileDiscovery

`struct SwiftFileDiscovery: Sendable`

Legacy Swift-only file discovery. Superseded by `SourceFileDiscovery` but retained for backward compatibility.

| Method | Signature |
|---|---|
| `findSwiftFiles` | `(in paths: [String]) throws -> [String]` |
