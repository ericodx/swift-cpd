# Swift Clone & Pattern Detector

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-orange?style=flat-square&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/swift-6.0%2B-orange?style=flat-square&logo=swift&logoColor=white)
[![CI](https://img.shields.io/github/actions/workflow/status/ericodx/swift-cpd/main-analysis.yml?branch=main&style=flat-square&logo=github&logoColor=white&label=CI&color=4CAF50)](https://github.com/ericodx/swift-cpd/actions)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=deploy-on-friday-swift-cpd)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=coverage)](https://sonarcloud.io/summary/new_code?id=deploy-on-friday-swift-cpd)

**Detect duplicated code in Swift and Objective-C/C codebases.**

`swift-cpd` is a Clone & Pattern Detector built on SwiftSyntax. It finds four types of code clones — from exact copies to semantically equivalent implementations — and integrates with the CLI, Xcode, SPM, CI pipelines, and git hooks.

## Clone types

| Type | Name | Description |
|---|---|---|
| 1 | Exact | Identical code after whitespace and comment removal |
| 2 | Parameterized | Same structure, different variable names or literals |
| 3 | Near-miss | Similar code with additions, deletions, or reordering |
| 4 | Semantic | Different implementation, equivalent behavior |

## Install

```bash
brew tap ericodx/homebrew-tools
brew install swift-cpd
```

Other installation methods — pre-built binary, build from source, pre-commit hook, Xcode plugin — are covered in the [Installation Guide](Docs/INSTALLATION.md).

## Quick start

```bash
# Generate a config file (auto-detects your source directories)
swift-cpd init

# Run
swift-cpd
```

Example output:

```
Clone detected — Type 2 | 15 lines | 120 tokens | 100.0% similarity
  Sources/App/Services/UserService.swift    :  34 –  48
  Sources/App/Services/ProductService.swift :  71 –  85

1 clone(s) found in 32 file(s) — 2.1% duplication — 0.8s
```

## Configuration

Drop a `.swift-cpd.yml` in the project root to control paths, thresholds, excluded files, and output format:

```yaml
paths:
  - Sources/
minimumTokenCount: 50
minimumLineCount: 5
enabledCloneTypes: [1, 2, 3, 4]
ignoreSameFile: true
exclude:
  - "**/*Tests*"
  - "**/*.generated.swift"
```

Full reference in the [Usage & Configuration Guide](Docs/USAGE.md).

## Documentation

| Document | Description |
|---|---|
| [Installation](Docs/INSTALLATION.md) | Homebrew, binary, source, pre-commit, Xcode plugin |
| [Usage & Configuration](Docs/USAGE.md) | CLI options, YAML config, output formats, CI integration |
| [Xcode Plugin](Docs/xcode-plugin.md) | Step-by-step Xcode and SPM plugin setup |
| [Architecture](Docs/Architecture/README.md) | System design, pipeline, detection algorithms |
| [CodeBase Reference](Docs/CodeBase/README.md) | Every type, protocol, and algorithm documented |
