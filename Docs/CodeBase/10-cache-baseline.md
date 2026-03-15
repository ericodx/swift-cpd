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
init(encoder: @escaping @Sendable ([String: CacheEntry]) throws -> Data = { try JSONEncoder().encode($0) })
```

The `encoder` parameter is injectable for testing.

```swift
func lookup(file: String, contentHash: String) -> CacheEntry?
```
Returns a cached entry if `file` is known **and** its stored `contentHash` matches the provided one. A hash mismatch means the file was modified — returns `nil`, triggering fresh tokenization.

```swift
func store(file: String, entry: CacheEntry)
```
Writes a new entry into the in-memory map (no disk write here).

```swift
func load(from directory: String) async
```
Reads `<directory>/cache.json` from disk (on a detached task) and merges the decoded entries into the actor's state.

```swift
func save(to directory: String) async
```
Encodes the current state on the actor, then writes the JSON to disk on a detached task. Creates the directory if needed.

### CacheEntry

```swift
struct CacheEntry: Sendable, Codable
let contentHash:      String       // SHA-256 hex string
let tokens:           [Token]      // original tokenization result
let normalizedTokens: [Token]      // after TokenNormalizer
```

`Codable` conformance persists the full token list including `location`, enabling exact reconstruction without re-parsing.

### FileHasher

```swift
struct FileHasher: Sendable
func hash(contentsOf filePath: String) throws -> String
```

Reads the file at `filePath` and returns its **SHA-256** digest as a lowercase hex string. Used to detect content changes between runs.

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
Reads and JSON-decodes the baseline file. Throws if the file is unreadable or malformed.

```swift
func save(_ entries: Set<BaselineEntry>, to filePath: String) throws
```
JSON-encodes and writes `entries` to `filePath`.

```swift
func entriesFromCloneGroups(_ groups: [CloneGroup]) -> Set<BaselineEntry>
```
Converts each `CloneGroup` to a `BaselineEntry` by computing a `FragmentFingerprint` per fragment. Discards exact column positions — only file and line range are retained.

```swift
func filterNewClones(_ groups: [CloneGroup], baseline: Set<BaselineEntry>) -> [CloneGroup]
```
Returns only the groups in `groups` that have **no matching** `BaselineEntry` in `baseline`. A group matches a baseline entry when its type, approximate token count, line count, and fragment fingerprints all correspond.

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

The fingerprint deliberately omits column numbers. This makes the baseline tolerant of code reformatting or minor edits above a clone that shift its line numbers slightly without changing its content.

### Baseline modes

| Mode | `BaselineMode` case | Behaviour |
|---|---|---|
| Generate | `.generate` | Run analysis; save all clones to baseline file; exit 0 |
| Update | `.update` | Same as generate — overwrites the existing baseline |
| Compare | `.compare` | Run analysis; load baseline; report only clones not in baseline |
| Off | `.none` | Run analysis; report all clones |

---

← [Reporting](09-reporting.md) | Next: [Plugin →](11-plugin.md)
