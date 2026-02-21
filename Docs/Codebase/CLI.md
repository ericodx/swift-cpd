# CLI

Handles command-line argument parsing, configuration merging, and application exit codes.

## Files

- `Sources/SwiftCPD/CLI/ArgumentParser.swift`
- `Sources/SwiftCPD/CLI/ArgumentParsingError.swift`
- `Sources/SwiftCPD/CLI/BaselineMode.swift`
- `Sources/SwiftCPD/CLI/Configuration.swift`
- `Sources/SwiftCPD/CLI/ConfigurationError.swift`
- `Sources/SwiftCPD/CLI/ExitCode.swift`
- `Sources/SwiftCPD/CLI/HelpText.swift`
- `Sources/SwiftCPD/CLI/OutputFormat.swift`
- `Sources/SwiftCPD/CLI/ParsedArguments.swift`

---

## ArgumentParser

`struct ArgumentParser: Sendable`

Parses `CommandLine.arguments` into a `ParsedArguments` struct. Supports commands (`init`), boolean flags (no value), and value flags (consume the next argument).

### Commands

| Command | Description |
|---|---|
| `init` | Generate a default `.swift-cpd.yml` configuration file |

### Boolean Flags

`--version`, `--help`, `--baseline-generate`, `--baseline-update`, `--cross-language`, `--ignore-same-file`, `--ignore-structural`

### Value Flags

| Flag | Type | Description |
|---|---|---|
| `--min-tokens` | `Int` | Minimum token count for clone detection |
| `--min-lines` | `Int` | Minimum line count for clone detection |
| `--format` | `OutputFormat` | Output format (text, json, html, xcode) |
| `--output` | `String` | Output file path |
| `--baseline` | `String` | Baseline file path for comparison |
| `--config` | `String` | YAML configuration file path |
| `--max-duplication` | `Double` | Maximum duplication percentage (0-100) |
| `--exclude` | `String` | Glob pattern to exclude (repeatable) |
| `--suppression-tag` | `String` | Inline suppression comment tag |
| `--types` | `Set<CloneType>` | Comma-separated clone types (1,2,3,4) or `all` |
| `--type3-similarity` | `Int` | Type-3 similarity threshold |
| `--type3-tile-size` | `Int` | Type-3 minimum tile size |
| `--type3-candidate-threshold` | `Int` | Type-3 candidate filter threshold |
| `--type4-similarity` | `Int` | Type-4 similarity threshold |

### Methods

| Method | Signature |
|---|---|
| `parse` | `(_ arguments: [String]) throws -> ParsedArguments` |

---

## ArgumentParsingError

`enum ArgumentParsingError: Error, Sendable, Equatable, CustomStringConvertible`

| Case | Description |
|---|---|
| `unknownFlag(String)` | Unrecognized `--flag` |
| `missingValue(String)` | Flag requires a value but none provided |
| `invalidIntegerValue(String, String)` | Value is not a valid integer |
| `invalidFormatValue(String)` | Value is not a valid output format |
| `invalidDuplicationValue(String)` | Value is not a valid duplication percentage |
| `invalidTypesValue(String)` | Value is not a valid clone type list |

---

## ParsedArguments

`struct ParsedArguments: Sendable, Equatable`

Intermediate struct holding raw parsed CLI arguments before merging with [YAML configuration](Configuration.md).

| Property | Type | Default |
|---|---|---|
| `paths` | `[String]` | `[]` |
| `minimumTokenCount` | `Int?` | `nil` |
| `minimumLineCount` | `Int?` | `nil` |
| `format` | `OutputFormat?` | `nil` |
| `outputFilePath` | `String?` | `nil` |
| `showVersion` | `Bool` | `false` |
| `showHelp` | `Bool` | `false` |
| `showInit` | `Bool` | `false` |
| `baselineGenerate` | `Bool` | `false` |
| `baselineUpdate` | `Bool` | `false` |
| `baselineFilePath` | `String?` | `nil` |
| `configFilePath` | `String?` | `nil` |
| `maxDuplication` | `Double?` | `nil` |
| `type3Similarity` | `Int?` | `nil` |
| `type3TileSize` | `Int?` | `nil` |
| `type3CandidateThreshold` | `Int?` | `nil` |
| `type4Similarity` | `Int?` | `nil` |
| `crossLanguageEnabled` | `Bool` | `false` |
| `ignoreSameFile` | `Bool` | `false` |
| `ignoreStructural` | `Bool` | `false` |
| `excludePatterns` | `[String]` | `[]` |
| `inlineSuppressionTag` | `String?` | `nil` |
| `enabledCloneTypes` | `Set<CloneType>?` | `nil` |

---

## Configuration

`struct Configuration: Sendable`

Final merged configuration. Values are resolved with priority: **CLI > YAML > default**.

See also: [YamlConfiguration](Configuration.md)

### Properties

| Property | Type | Default | Valid Range |
|---|---|---|---|
| `paths` | `[String]` | (required) | |
| `minimumTokenCount` | `Int` | `50` | 10 - 500 |
| `minimumLineCount` | `Int` | `5` | 2 - 100 |
| `outputFormat` | `OutputFormat` | `.text` | |
| `outputFilePath` | `String?` | `nil` | |
| `baselineMode` | `BaselineMode` | `.none` | |
| `baselineFilePath` | `String` | `".swiftcpd-baseline.json"` | |
| `maxDuplication` | `Double?` | `nil` | 0 - 100 |
| `type3Similarity` | `Int` | `70` | 50 - 100 |
| `type3TileSize` | `Int` | `5` | 2 - 20 |
| `type3CandidateThreshold` | `Int` | `30` | 10 - 80 |
| `type4Similarity` | `Int` | `80` | 60 - 100 |
| `crossLanguageEnabled` | `Bool` | `false` | |
| `ignoreSameFile` | `Bool` | `false` | |
| `ignoreStructural` | `Bool` | `false` | |
| `excludePatterns` | `[String]` | `[]` | |
| `inlineSuppressionTag` | `String` | `"swiftcpd:ignore"` | |
| `enabledCloneTypes` | `Set<CloneType>` | all types | |

### Related Types

**`BaselineMode`** — `Sources/SwiftCPD/CLI/BaselineMode.swift`

`enum BaselineMode: Sendable, Equatable`

| Case | Trigger |
|---|---|
| `.none` | No baseline flags |
| `.generate` | `--baseline-generate` |
| `.update` | `--baseline-update` |
| `.compare` | `--baseline <path>` |

**`ConfigurationError`** — `Sources/SwiftCPD/CLI/ConfigurationError.swift`

`enum ConfigurationError: Error, Sendable, Equatable`

| Case | Description |
|---|---|
| `noPathsSpecified` | No paths provided via CLI or YAML |
| `parameterOutOfRange(name:value:validRange:)` | Parameter outside valid range |

---

## ExitCode

`enum ExitCode: Int32, Sendable`

| Case | Value | Description |
|---|---|---|
| `success` | `0` | No clones found or report generated |
| `clonesDetected` | `1` | Clones found (or max duplication exceeded) |
| `configurationError` | `2` | Invalid arguments or configuration |
| `analysisError` | `3` | Runtime error during analysis |

---

## OutputFormat

`enum OutputFormat: String, Sendable`

| Case | Description | Reporter |
|---|---|---|
| `text` | Human-readable text | [TextReporter](Reporting.md#textreporter) |
| `json` | Structured JSON | [JsonReporter](Reporting.md#jsonreporter) |
| `html` | Standalone HTML page | [HtmlReporter](Reporting.md#htmlreporter) |
| `xcode` | Xcode build warnings | [XcodeReporter](Reporting.md#xcodereporter) |

---

## HelpText

`enum HelpText`

Static computed property `usage` that returns the CLI help text.
