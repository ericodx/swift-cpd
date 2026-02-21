# Baseline

Baseline system for tracking known clones. Enables incremental adoption by reporting only new clones not present in the baseline.

## Files

- `Sources/SwiftCPD/Baseline/BaselineStore.swift`
- `Sources/SwiftCPD/Baseline/BaselineEntry.swift`
- `Sources/SwiftCPD/Baseline/FragmentFingerprint.swift`

---

## BaselineStore

`struct BaselineStore: Sendable`

Loads, saves, and compares baseline files. Uses JSON format for persistence.

**Default file:** `.swiftcpd-baseline.json`

| Method | Signature | Description |
|---|---|---|
| `load` | `(from filePath: String) throws -> Set<BaselineEntry>` | Loads baseline from JSON file |
| `save` | `(_ entries: Set<BaselineEntry>, to filePath: String) throws` | Saves baseline to JSON file |
| `entriesFromCloneGroups` | `(_ groups: [CloneGroup]) -> Set<BaselineEntry>` | Converts clone groups to baseline entries |
| `filterNewClones` | `(_ groups: [CloneGroup], baseline: Set<BaselineEntry>) -> [CloneGroup]` | Returns only clones not in the baseline |

### Filtering Logic

`filterNewClones` converts current clone groups into `BaselineEntry` sets and performs set subtraction (`current - baseline`). Only groups whose entries are not present in the baseline are returned.

---

## BaselineEntry

`struct BaselineEntry: Sendable, Codable, Equatable, Hashable`

A single entry in the baseline file. Identifies a clone group by its characteristics and fragment locations.

| Property | Type | Description |
|---|---|---|
| `type` | `Int` | Clone type raw value (1-4) |
| `tokenCount` | `Int` | Number of tokens |
| `lineCount` | `Int` | Number of lines |
| `fragmentFingerprints` | `[FragmentFingerprint]` | Locations of each fragment |

---

## FragmentFingerprint

`struct FragmentFingerprint: Sendable, Codable, Equatable, Hashable`

Identifies a clone fragment by file and line range. Used for matching against baseline entries.

| Property | Type |
|---|---|
| `file` | `String` |
| `startLine` | `Int` |
| `endLine` | `Int` |
