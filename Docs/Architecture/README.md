# Architecture Documentation

`swift-cpd` is a static analysis tool that detects code clones in Swift (and optionally Objective-C/C) projects. It runs as a CLI tool and integrates natively with SPM and Xcode via a build plugin.

## Documents

| Document | Contents |
|---|---|
| [01 — Overview](01-overview.md) | System purpose, module map, entry point |
| [02 — Pipeline](02-pipeline.md) | Analysis pipeline stages and data flow |
| [03 — Detection](03-detection.md) | Clone types and detection algorithms |
| [04 — Tokenization](04-tokenization.md) | Tokenization, normalization and cross-language support |
| [05 — Supporting Systems](05-supporting-systems.md) | Configuration, cache, baseline, suppression and reporting |

## Quick Reference

```
swift-cpd [options] <paths>
swift-cpd init # generate .swift-cpd.yml
```

**Exit codes:** `0` success · `1` clones detected · `2` configuration error · `3` analysis error
