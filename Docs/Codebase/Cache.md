# Cache

File-based tokenization cache. Avoids re-tokenizing unchanged files across multiple runs.

## Files

- `Sources/SwiftCPD/Cache/FileCache.swift`
- `Sources/SwiftCPD/Cache/CacheEntry.swift`
- `Sources/SwiftCPD/Cache/FileHasher.swift`

---

## FileCache

`actor FileCache`

Thread-safe cache manager using actor isolation. Accessed concurrently from the [pipeline](Pipeline.md)'s parallel tokenization tasks.

**Storage location:** `.swiftcpd-cache/cache.json`

**Cache key:** file path + SHA-256 content hash

| Method | Signature | Description |
|---|---|---|
| `lookup` | `(file: String, contentHash: String) -> CacheEntry?` | Returns cached entry if hash matches |
| `store` | `(file: String, entry: CacheEntry)` | Stores a new cache entry |
| `load` | `(from directory: String) throws` | Loads cache from disk |
| `save` | `(to directory: String) throws` | Persists cache to disk |

---

## CacheEntry

`struct CacheEntry: Sendable, Codable`

A cached tokenization result for a single file.

| Property | Type | Description |
|---|---|---|
| `contentHash` | `String` | SHA-256 hash of file contents |
| `tokens` | `[Token]` | Raw tokens |
| `normalizedTokens` | `[Token]` | Normalized tokens |

---

## FileHasher

`struct FileHasher: Sendable`

Computes SHA-256 hashes of file contents using CryptoKit.

| Method | Signature | Description |
|---|---|---|
| `hash` | `(contentsOf filePath: String) throws -> String` | Returns hex-encoded SHA-256 hash |
