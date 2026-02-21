# Configuration

YAML configuration file support. Allows project-level settings via `.swift-cpd.yml`.

See also: [CLI Configuration](CLI.md#configuration) for the final merged configuration.

## Files

- `Sources/SwiftCPD/Configuration/YamlConfiguration.swift`
- `Sources/SwiftCPD/Configuration/YamlConfigurationError.swift`
- `Sources/SwiftCPD/Configuration/YamlConfigurationLoader.swift`

---

## YamlConfiguration

`struct YamlConfiguration: Decodable, Sendable, Equatable`

Data structure representing the contents of a `.swift-cpd.yml` file. All properties are optional — they serve as defaults when no CLI argument is provided.

| Property | Type |
|---|---|
| `minimumTokenCount` | `Int?` |
| `minimumLineCount` | `Int?` |
| `outputFormat` | `String?` |
| `paths` | `[String]?` |
| `maxDuplication` | `Double?` |
| `type3Similarity` | `Int?` |
| `type3TileSize` | `Int?` |
| `type3CandidateThreshold` | `Int?` |
| `type4Similarity` | `Int?` |
| `crossLanguageEnabled` | `Bool?` |
| `ignoreSameFile` | `Bool?` |
| `ignoreStructural` | `Bool?` |
| `exclude` | `[String]?` |
| `inlineSuppressionTag` | `String?` |
| `enabledCloneTypes` | `[Int]?` |

---

## YamlConfigurationLoader

`struct YamlConfigurationLoader: Sendable`

Loads and parses YAML configuration files using the Yams library.

| Method | Signature | Description |
|---|---|---|
| `load` | `(from filePath: String) throws -> YamlConfiguration` | Loads and decodes the YAML file. Throws on read or parse failure. |
| `loadIfExists` | `(from filePath: String) throws -> YamlConfiguration?` | Returns `nil` if the file does not exist. Throws only on parse failure. |

### YamlConfigurationError

`Sources/SwiftCPD/Configuration/YamlConfigurationError.swift`

`enum YamlConfigurationError: Error, Sendable, Equatable, CustomStringConvertible`

| Case | Description |
|---|---|
| `fileNotReadable(String)` | File exists but cannot be read |
| `invalidYaml(String)` | File content is not valid YAML |
