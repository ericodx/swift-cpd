# Swift Code Duplication Detector

[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fericodx%2Fswift-cpd%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ericodx/swift-cpd)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fericodx%2Fswift-cpd%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ericodx/swift-cpd)
[![CI](https://img.shields.io/github/actions/workflow/status/ericodx/swift-cpd/main-analysis.yml?branch=main&style=flat-square&logo=github&logoColor=white&label=CI&color=4CAF50)](https://github.com/ericodx/swift-cpd/actions)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=deploy-on-friday-swift-cpd)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=deploy-on-friday-swift-cpd&metric=coverage)](https://sonarcloud.io/summary/new_code?id=deploy-on-friday-swift-cpd)

**Detect and eliminate duplicated logic in Swift and Objective-C/C codebases to improve maintainability and code quality.**

`swift-cpd` performs structural analysis to detect duplication patterns across Swift, Objective-C, and C codebases, going beyond simple text-based detection.

---

## Why

Code duplication leads to:
- inconsistent behavior across features
- fragile refactors and hidden regressions
- increased maintenance cost and cognitive load

`swift-cpd` helps you detect and address duplication early, supporting long-term code health and developer productivity.

---

## Features

- Structural duplication detection (AST-based)
- Works with Swift, Objective-C, and C codebases
- Enforces duplication rules in CI pipelines
- Supports code quality and governance practices

---

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
