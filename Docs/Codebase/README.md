# Codebase Reference

Reference documentation for every module and type in the Swift CPD codebase.

For high-level architecture and diagrams, see [Architecture](../Architecture/README.md).

---

## Entry Point

### SwiftCPD

`Sources/SwiftCPD/SwiftCPD.swift`

The `@main` struct that orchestrates the entire application. Parses arguments, loads configuration, runs the analysis pipeline, handles baseline operations, and writes output.

| Method | Description |
|--------|-------------|
| `main()` | Entry point. Parses CLI args, loads config, runs analysis |
| `runAnalysis(_:)` | Executes the pipeline and builds `AnalysisResult` |
| `handleReport(_:_:)` | Formats and writes the report |
| `handleBaselineGenerate(_:_:)` | Saves current clones as baseline |
| `handleBaselineUpdate(_:_:)` | Overwrites existing baseline |
| `handleBaselineCompare(_:_:)` | Filters clones against baseline |
| `makeReporter(_:)` | Creates the appropriate reporter for the output format |
| `writeOutput(_:to:)` | Writes to stdout or file |
| `loadYamlConfiguration(_:)` | Loads YAML config if available |

### Version

`Sources/SwiftCPD/Version.swift`

Static version information.

| Property | Value |
|----------|-------|
| `name` | `"swift-cpd"` |
| `number` | `"0.0.0-dev"` |
| `current` | Formatted string with name, version, platform info |

---

## Modules

| Module | Description | Reference |
|--------|-------------|-----------|
| CLI | Argument parsing, configuration, exit codes | [CLI](CLI.md) |
| Configuration | YAML configuration file support | [Configuration](Configuration.md) |
| FileDiscovery | Recursive source file discovery | [FileDiscovery](FileDiscovery.md) |
| Pipeline | Analysis orchestration and progress reporting | [Pipeline](Pipeline.md) |
| Tokenization | Swift and C-family tokenizers, normalization | [Tokenization](Tokenization.md) |
| Detection | Clone detection algorithms (Type-1 to Type-4) | [Detection](Detection.md) |
| SemanticGraph | Abstract Semantic Graph for Type-4 detection | [SemanticGraph](SemanticGraph.md) |
| Reporting | Output formatters (text, JSON, HTML, Xcode) | [Reporting](Reporting.md) |
| Cache | File-based tokenization cache | [Cache](Cache.md) |
| Baseline | Baseline comparison system | [Baseline](Baseline.md) |
| Suppression | Inline suppression scanning | [Suppression](Suppression.md) |
| Plugin | SPM Build Tool Plugin | [Plugin](Plugin.md) |
