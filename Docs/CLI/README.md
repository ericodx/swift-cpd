# CLI

Command-line interface for Swift CPD.

---

## Source Structure

```text
Sources/SwiftCPD/CLI/
├── ArgumentParser.swift        Parses CLI arguments
├── ArgumentParsingError.swift   Parsing error types
├── Configuration.swift          Merged configuration (CLI + YAML + defaults)
├── ExitCode.swift               Exit code definitions
├── HelpText.swift               Help and usage text
├── OutputFormat.swift            Output format enum
└── ParsedArguments.swift         Raw parsed arguments
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Usage](Usage.md) | Commands, flags, examples, and YAML configuration |
| [CLI Reference](../Codebase/CLI.md) | Internal types and implementation details |

---

## Configuration Precedence

| Priority | Source |
|----------|--------|
| 1 (highest) | CLI flags |
| 2 | YAML configuration file |
| 3 (lowest) | Built-in defaults |

---

## Exit Codes

| Code | Constant | Meaning |
|------|----------|---------|
| `0` | `success` | No clones detected (or within threshold) |
| `1` | `clonesDetected` | Clones detected (or above threshold) |
| `2` | `configurationError` | Invalid arguments or configuration |
| `3` | `analysisError` | Runtime failure |
