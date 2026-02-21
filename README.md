# Swift Clone & Pattern Detector

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-orange?style=flat-square&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/swift-6.0%2B-orange?style=flat-square&logo=swift&logoColor=white)
[![CI](https://img.shields.io/github/actions/workflow/status/ericodx/swift-cpd/main-analysis.yml?branch=main&style=flat-square&logo=github&logoColor=white&label=CI&color=4CAF50)](https://github.com/ericodx/swift-cpd/actions)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=alert_status)](https://sonarcloud.io/project/overview?id=deploy-on-friday-swift-cpd)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=coverage)](https://sonarcloud.io/project/overview?id=deploy-on-friday-swift-cpd)

**Detect duplicated code in Swift and Objective-C/C codebases.**

Swift CPD is a Clone & Pattern Detector built on SwiftSyntax. It finds exact copies, parameterized clones, structural similarities, and semantically equivalent code across your project.

---

## What Swift CPD Does

- Detects **Type-1/Type-2** clones (exact and parameterized copies)
- Detects **Type-3** clones (structural similarity with gaps via Greedy String Tiling)
- Detects **Type-4** clones (semantic equivalence via AST-based behavior analysis)
- Supports cross-language detection between Swift and Objective-C/C
- Provides inline suppression with `// swiftcpd:ignore`
- Tracks known duplications with baseline workflow
- Produces deterministic, reproducible output

---

## Installation

The recommended way to install Swift Clone & Pattern Detector is via Homebrew:

```bash
brew tap ericodx/homebrew-tools
brew install swift-cpd
```

### Other Installation Methods

**[View Complete Installation Guide](Docs/INSTALLATION.md)**

- Swift Package Manager plugin
- Manual build from source
- Direct download of pre-compiled binaries

---

## Usage

```bash
# Analyze Sources directory
swift-cpd Sources/

# JSON output with custom thresholds
swift-cpd --format json --min-tokens 30 --min-lines 3 Sources/

# Fail if duplication exceeds 5%
swift-cpd --max-duplication 5 Sources/

# HTML report to file
swift-cpd --format html --output report.html Sources/

# Xcode-compatible warnings
swift-cpd --format xcode Sources/

# Exclude generated files
swift-cpd --exclude "*.generated.swift" --exclude "**/Generated/**" Sources/

# Ignore same-file clones (cross-file only)
swift-cpd --ignore-same-file Sources/

# Ignore structural clones (Type-3/Type-4)
swift-cpd --ignore-structural Sources/
```

See [CLI Usage Reference](Docs/CLI/Usage.md) for the complete list of options and flags.

---

## Xcode Integration

### Build Tool Plugin (Recommended)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ericodx/swift-cpd.git", from: "1.0.0"),
]

targets: [
    .target(
        name: "MyApp",
        plugins: [
            .plugin(name: "SwiftCPDPlugin", package: "SwiftCPD")
        ]
    ),
]
```

**Xcode Projects:**

1. Add `swift-cpd` as a package dependency
2. Select your target > **Build Phases**
3. Add **SwiftCPDPlugin** to "Run Build Tool Plug-ins"

See [Xcode Plugin Installation](Docs/Integration/XcodePlugin.md) for complete setup.

---

## CI Integration

### GitHub Actions

```yaml
- name: Check duplication
  run: swift-cpd --max-duplication 5 --format xcode Sources/
```

### With Baseline

```yaml
- name: Check for new duplications
  run: swift-cpd --baseline .swiftcpd-baseline.json --format xcode Sources/
```

---

## Configuration

Swift CPD uses **`.swift-cpd.yml`** for configuration.

```bash
# Initialize configuration file
swift-cpd init
```

See [CLI Usage Reference](Docs/CLI/Usage.md) for configuration options and precedence rules.

### Inline Suppression

```swift
// swiftcpd:ignore
func knownDuplicate() {
    // This block is excluded from detection
}
```

### Baseline Workflow

```bash
# Generate initial baseline
swift-cpd --baseline-generate Sources/

# Compare against baseline (fails only on new clones)
swift-cpd --baseline .swiftcpd-baseline.json Sources/

# Update baseline after accepting new clones
swift-cpd --baseline-update Sources/
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No clones detected (or within threshold) |
| `1` | Clones detected (or above threshold) |
| `2` | Configuration error |
| `3` | Analysis error |

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](Docs/Architecture/README.md) | System design and pipeline pattern |
| [Codebase](Docs/Codebase/README.md) | Module reference and implementation details |
| [CLI Usage](Docs/CLI/Usage.md) | Commands, flags, and configuration |
| [Installation](Docs/INSTALLATION.md) | Homebrew, SPM, and manual build |
| [Xcode Plugin](Docs/Integration/XcodePlugin.md) | Build tool plugin setup |

---

## License

MIT
