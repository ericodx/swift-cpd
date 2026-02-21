# Swift CPD Documentation

Documentation for the Swift Clone & Pattern Detector.

---

## Quick Links

| Audience | Document |
|----------|----------|
| **New users** | [Installation](INSTALLATION.md) |
| **CLI users** | [CLI Usage](CLI/Usage.md) |
| **Xcode users** | [Xcode Plugin](Integration/XcodePlugin.md) |
| **Contributors** | [Architecture](Architecture/README.md) |
| **Codebase reference** | [Codebase](Codebase/README.md) |

---

## Documentation Modules

| Module | Description |
|--------|-------------|
| [Installation](INSTALLATION.md) | Homebrew, SPM, and manual build |
| [Architecture](Architecture/README.md) | Pipeline pattern, module dependencies, concurrency model |
| [CLI](CLI/README.md) | Argument parsing, configuration, and exit codes |
| [Codebase](Codebase/README.md) | Module reference: tokenization, detection, reporting, and more |
| [Integration](Integration/README.md) | Xcode plugin and CI/CD workflows |
| [CI](CI/README.md) | GitHub Actions workflows |

---

## Source Structure

```text
Sources/SwiftCPD/
├── Baseline/           Baseline file management
├── Cache/              Tokenization cache with SHA-256
├── CLI/                Argument parsing and configuration
├── Detection/          Clone detection algorithms (Type 1-4)
│   └── SemanticGraph/  AST-based semantic analysis
├── FileDiscovery/      Source file discovery and glob matching
├── Pipeline/           Analysis orchestration
├── Reporting/          Output formatters (text, JSON, HTML, Xcode)
├── Suppression/        Inline suppression scanner
└── Tokenization/       Swift and C-family tokenizers
```
