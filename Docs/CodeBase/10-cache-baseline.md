# Cache & Baseline

← [Reporting](09-reporting.md) | Next: [Plugin →](11-plugin.md)

---

## Cache

The cache avoids re-tokenizing files that have not changed since the last run. It is transparent to the pipeline: the same `FileTokens` are produced whether they come from cache or fresh tokenization.

### FileCache

```swift
actor FileCache
```

An `actor` that owns the in-memory entry map and serializes all reads and writes. I/O operations are offloaded to `Task.detached` to avoid blocking the actor's executor while the caller awaits.

```swift
init(encoder: @escaping @Sendable (Envelope) throws -> Data = { try JSONEncoder().encode($0) })
```

The `encoder` parameter is injectable for testing. The current schema version is exposed as `static let currentSchemaVersion = 2`.

```swift
func lookup(key: CacheKey, contentHash: String) -> CacheEntry?
```
Returns a cached entry if `key` is known **and** its stored `contentHash` matches the provided one. A hash mismatch means the file was modified — returns `nil`, triggering fresh tokenization.

```swift
func store(key: CacheKey, entry: CacheEntry)
```
Writes a new entry into the in-memory map (no disk write here).

```swift
func load(from directory: String) async
```
Reads `<directory>/cache.json` from disk (on a detached task), decodes the envelope, and adopts its `entries` map into the actor's state — but only if `schemaVersion` matches `currentSchemaVersion`. A missing file, read error, decoding failure or mismatched version leaves the in-memory map unchanged (empty on a fresh actor), so the cache is silently invalidated.

```swift
func save(to directory: String) async
```
Wraps the current entries in an `Envelope` with the current schema version and encodes it with the injected `encoder`, then writes `<directory>/cache.json` on a detached task. Creates the directory if needed. Encoding and write errors are swallowed — if encoding fails, nothing is written.

### CacheKey

```swift
struct CacheKey: Hashable, Sendable
init(file: String, resolvedSha: String? = nil)

let file:        String
let resolvedSha: String?

var encoded: String          // "<resolvedSha>|<file>" or "<file>" when resolvedSha is nil
```

The on-disk dictionary key. When `resolvedSha` is `nil`, the working-tree namespace is used (just the path). When a git ref is in play, the resolved SHA prefixes the path so multiple refs of the same file can coexist in the cache without collision.

### Envelope (schema v2)

Nested type `FileCache.Envelope`, declared in `FileCache+Envelope.swift`.

```swift
struct Envelope: Codable, Sendable
let schemaVersion: Int
let entries:       [String: CacheEntry]   // keyed by CacheKey.encoded
```

The cache file on disk is a single `Envelope`. Current `schemaVersion` is `2`.

When `load` reads a file with a different `schemaVersion` — or with the legacy v1 flat-dictionary format — it discards the contents and starts empty. This is a deliberate **one-shot invalidation**: the next run pays one full tokenization pass, then steady state resumes. There is no migration path between schemas.

### CacheEntry

```swift
struct CacheEntry: Sendable, Codable
let contentHash:      String       // SHA-256 hex string
let tokens:           [Token]      // tokenizer output after cross-language mapping and suppression filtering
let normalizedTokens: [Token]      // tokens after TokenNormalizer
```

`Codable` conformance persists the full token list including `location`, enabling exact reconstruction without re-parsing.

### FileHasher

```swift
struct FileHasher: Sendable
func hash(data: Data) -> String
```

Returns the **SHA-256** digest of the input as a lowercase hex string. Used to detect content changes between runs. The pipeline hashes the bytes returned by `SourceReader.read(file:)` — the same call that produced the `Data` is reused, so no second filesystem read happens.

---

## Baseline

The baseline system records a snapshot of known clones so that only newly introduced clones are reported on subsequent runs.

### BaselineStore

```swift
struct BaselineStore: Sendable
```

```swift
func load(from filePath: String) throws -> Set<BaselineEntry>
```
Reads and JSON-decodes the baseline file (a JSON array of `BaselineEntry`). Returns an empty set when the file does not exist; throws if it exists but is unreadable or malformed.

```swift
func save(_ entries: Set<BaselineEntry>, to filePath: String) throws
```
Sorts `entries` (type ascending → token count descending → first fingerprint file), encodes them as a pretty-printed JSON array with sorted keys, and writes the result to `filePath`.

```swift
func entriesFromCloneGroups(_ groups: [CloneGroup]) -> Set<BaselineEntry>
```
Converts each `CloneGroup` to a `BaselineEntry` by computing a `FragmentFingerprint` per fragment. Discards exact column positions — only file and line range are retained.

```swift
func filterNewClones(_ groups: [CloneGroup], baseline: Set<BaselineEntry>) -> [CloneGroup]
```
Returns only the groups in `groups` that have **no matching** `BaselineEntry` in `baseline`. Matching is exact `BaselineEntry` equality: type, token count, line count, and the ordered list of fragment fingerprints must all be identical.

### BaselineEntry

```swift
struct BaselineEntry: Sendable, Codable, Equatable, Hashable
let type:                 Int                   // CloneType.rawValue
let tokenCount:           Int
let lineCount:            Int
let fragmentFingerprints: [FragmentFingerprint]
```

### FragmentFingerprint

```swift
struct FragmentFingerprint: Sendable, Codable, Equatable, Hashable
let file:      String
let startLine: Int
let endLine:   Int
```

The fingerprint deliberately omits column numbers, so changes that only move a clone horizontally (e.g. re-indentation) keep it matched. Line numbers are part of the fingerprint, though: any edit that shifts a clone's start or end line makes it a new entry and it is reported again in compare mode.

### Baseline modes

| Mode | `BaselineMode` case | Behaviour |
|---|---|---|
| Generate | `.generate` | Run analysis; save all clones to baseline file; print `Baseline generated with N clone(s) at <path>`; exit 0 (no report is produced) |
| Update | `.update` | Same as generate — overwrites the existing baseline and prints `Baseline updated …` |
| Compare | `.compare` | Run analysis; load baseline (missing file = empty baseline); report only clones not in baseline |
| Off | `.none` | Run analysis; report all clones |

Baselines are built from the clone groups that remain after `ignoreSameFile` / `ignoreStructural` filtering.

---

← [Reporting](09-reporting.md) | Next: [Plugin →](11-plugin.md)
