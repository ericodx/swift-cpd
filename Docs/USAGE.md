# Usage & Configuration Guide

This guide covers every way to run and configure `swift-cpd`, from a first run to full CI integration.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Configuration File](#configuration-file)
3. [CLI Reference](#cli-reference)
4. [Output Formats](#output-formats)
5. [Baseline Workflow](#baseline-workflow)
6. [Inline Suppression](#inline-suppression)
7. [CI/CD Integration](#cicd-integration)
8. [Xcode & SPM Plugin](#xcode--spm-plugin)
9. [Exit Codes](#exit-codes)

---

## Quick Start

### SPM project

```bash
# Generate a default config file (auto-detects source paths)
swift-cpd init

# Run with the generated config
swift-cpd

# Or pass paths directly without a config file
swift-cpd Sources/
```

### Xcode project

```bash
# Auto-detects your target folder (e.g. MyApp/)
swift-cpd init

# Edit .swift-cpd.yml if needed, then run
swift-cpd
```

### First-time output (text format)

```
Clone detected — Type 2 | 18 lines | 142 tokens | 100.0% similarity
  Sources/MyApp/Networking/UserService.swift  :  45 –  62
  Sources/MyApp/Networking/ProductService.swift :  91 – 108

Clone detected — Type 3 | 24 lines | 198 tokens | 73.4% similarity
  Sources/MyApp/ViewModels/ListViewModel.swift  :  12 –  35
  Sources/MyApp/ViewModels/DetailViewModel.swift :  18 –  41

──────────────────────────────────────────────────
2 clone(s) found in 47 file(s) — 4.2% duplication — 1.3s
```

---

## Configuration File

`swift-cpd` looks for `.swift-cpd.yml` in the current directory by default. Generate a starter file with:

```bash
swift-cpd init
```

### Full reference

```yaml
# ── Paths ────────────────────────────────────────────────────────────────────

# Directories to analyze. Accepts multiple entries.
# swift-cpd init fills this automatically based on your project layout.
paths:
  - Sources/
  - Plugins/

# ── Detection thresholds ─────────────────────────────────────────────────────

# Minimum number of tokens a fragment must have to be reported as a clone.
# Lower values find smaller clones but increase noise. Range: 10–500.
minimumTokenCount: 50

# Minimum number of lines a fragment must span. Range: 2–100.
minimumLineCount: 5

# Clone types to detect. Remove entries to skip specific detectors.
# Type 1/2: exact/parameterized (fast). Type 3: near-miss. Type 4: semantic.
enabledCloneTypes:
  - 1
  - 2
  - 3
  - 4

# ── Type 3 (near-miss) tuning ────────────────────────────────────────────────

# Minimum Greedy String Tiling similarity to report a Type 3 clone. Range: 50–100.
type3Similarity: 70

# Minimum matching tile length for GST. Smaller values find more fragmented matches.
# Range: 2–20.
type3TileSize: 5

# Jaccard pre-filter threshold. Pairs below this are skipped before GST runs.
# Lower values increase recall at the cost of speed. Range: 10–80.
type3CandidateThreshold: 30

# ── Type 4 (semantic) tuning ─────────────────────────────────────────────────

# Minimum combined semantic similarity to report a Type 4 clone. Range: 60–100.
type4Similarity: 80

# ── Output ────────────────────────────────────────────────────────────────────

# Output format: text | json | html | xcode
outputFormat: text

# ── Filters ──────────────────────────────────────────────────────────────────

# Ignore clones where both fragments are in the same file.
ignoreSameFile: true

# Ignore Type 3 and Type 4 (structural/semantic) clones.
ignoreStructural: true

# Glob patterns for files to exclude. Evaluated against the full file path.
# Relative patterns match at path-component boundaries anywhere in the absolute path.
# Patterns ending with / exclude that directory and all files within it.
exclude:
  - "**/*Tests*"
  - "**/Generated/**"
  - "**/*.generated.swift"
  - "Sources/MyApp/Discovery/Operators/"

# ── Cache ─────────────────────────────────────────────────────────────────────

# Disable caching of tokenization results.
# When true, files are re-tokenized on every run and no cache is read or written.
# noCache: true

# ── Cross-language ────────────────────────────────────────────────────────────

# Also analyze Objective-C/C files (.m, .mm, .h, .c, .cpp).
crossLanguageEnabled: false

# ── Suppression ───────────────────────────────────────────────────────────────

# Comment tag used to suppress specific regions from analysis.
inlineSuppressionTag: swiftcpd:ignore

# ── CI quality gate ───────────────────────────────────────────────────────────

# Exit with code 1 if the duplication percentage exceeds this value.
# Remove this key to disable the quality gate.
maxDuplication: 5.0
```

### Precedence

When a value is set in both the CLI and the YAML file, the CLI value always wins.

```
CLI argument  >  .swift-cpd.yml  >  built-in default
```

The `--config` flag lets you point to a different YAML file:

```bash
swift-cpd --config ci/swift-cpd-strict.yml Sources/
```

---

## CLI Reference

### Commands

```bash
swift-cpd init                   # generate .swift-cpd.yml in the current directory
swift-cpd --version              # print version and platform info
swift-cpd --help                 # print usage summary
```

### Running an analysis

```bash
swift-cpd [options] [paths...]
```

Paths on the CLI override `paths:` in the YAML file. When no paths are given, the YAML file must specify them.

### All options

| Option | Default | Valid range | Description |
|---|---|---|---|
| `--min-tokens <N>` | `50` | 10–500 | Minimum clone length in tokens |
| `--min-lines <N>` | `5` | 2–100 | Minimum clone length in lines |
| `--types <list>` | `all` | `1,2,3,4` or `all` | Clone types to detect |
| `--format <fmt>` | `text` | `text json html xcode` | Output format |
| `--output <path>` | stdout | — | Write output to a file |
| `--exclude <pattern>` | — | glob | Exclude matching files (repeatable) |
| `--ignore-same-file` | true | — | Skip clones within one file |
| `--ignore-structural` | true | — | Skip Type 3 and Type 4 clones |
| `--no-cache` | false | — | Disable tokenization cache |
| `--cross-language` | false | — | Include Objective-C/C files |
| `--suppression-tag <tag>` | `swiftcpd:ignore` | — | Custom suppression comment tag |
| `--max-duplication <N>` | — | 0–100 | Fail if duplication % exceeds N |
| `--type3-similarity <N>` | `70` | 50–100 | Type 3 GST similarity threshold |
| `--type3-tile-size <N>` | `5` | 2–20 | Type 3 minimum tile length |
| `--type3-candidate-threshold <N>` | `30` | 10–80 | Type 3 Jaccard pre-filter |
| `--type4-similarity <N>` | `80` | 60–100 | Type 4 semantic similarity threshold |
| `--baseline-generate` | — | — | Save current clones as baseline |
| `--baseline-update` | — | — | Overwrite existing baseline |
| `--baseline <path>` | `.swift-cpd-baseline.json` | — | Compare against baseline at path |
| `--config <path>` | `.swift-cpd.yml` | — | Use a specific config file |

### Common invocations

```bash
# Analyze a single directory
swift-cpd Sources/

# Analyze multiple directories
swift-cpd Sources/ Plugins/

# Only exact and parameterized clones (fast, no semantic analysis)
swift-cpd --types 1,2 Sources/

# Strict: report same-file clones, include structural clones
swift-cpd --min-tokens 30 --min-lines 3 Sources/

# Exclude test files and generated code
swift-cpd --exclude "**/*Tests*" --exclude "**/*.generated.swift" Sources/

# Save report to a file
swift-cpd --format json --output report.json Sources/

# Enable Objective-C detection for a mixed project
swift-cpd --cross-language Sources/ ObjcSources/

# Fail CI if duplication exceeds 3%
swift-cpd --max-duplication 3 Sources/

# Run without cache (useful after changing detection rules)
swift-cpd --no-cache Sources/
```

---

## Output Formats

### text (default)

Human-readable output for interactive use. Prints each clone with file locations and a duplication summary.

```bash
swift-cpd --format text Sources/
```

```
Clone detected — Type 1 | 10 lines | 82 tokens | 100.0% similarity
  Sources/App/Cache/DiskCache.swift      :  14 –  23
  Sources/App/Cache/MemoryCache.swift    :  31 –  40
```

### json

Structured output for programmatic consumption. All fields are stable across versions.

```bash
swift-cpd --format json --output report.json Sources/
```

```json
{
  "metadata": {
    "version": "swift-cpd 1.0.0 [arm64-macos15]",
    "timestamp": "2026-03-13T14:00:00Z",
    "executionTime": 1.24
  },
  "summary": {
    "totalClones": 2,
    "filesAnalyzed": 47,
    "totalTokens": 18430,
    "duplicationPercentage": 4.2
  },
  "byType": { "type1": 1, "type2": 1, "type3": 0, "type4": 0 },
  "clones": [
    {
      "type": 1,
      "similarity": 100.0,
      "tokenCount": 82,
      "lineCount": 10,
      "fragments": [
        {
          "file": "Sources/App/Cache/DiskCache.swift",
          "startLine": 14, "endLine": 23,
          "startColumn": 5, "endColumn": 1,
          "preview": "    func store(_ value: ...\n    ..."
        },
        {
          "file": "Sources/App/Cache/MemoryCache.swift",
          "startLine": 31, "endLine": 40,
          "startColumn": 5, "endColumn": 1,
          "preview": "    func store(_ value: ...\n    ..."
        }
      ]
    }
  ]
}
```

### html

A self-contained HTML report suitable for sharing or archiving.

```bash
swift-cpd --format html --output report.html Sources/
open report.html
```

### xcode

One diagnostic per fragment in the format Xcode recognizes as a build warning. Used automatically by the build plugin; rarely needed from the CLI directly.

```bash
swift-cpd --format xcode Sources/
```

```
/path/to/DiskCache.swift:14:5: warning: Clone detected (Type 1, 82 tokens, 10 lines, 100.0% similarity)
/path/to/MemoryCache.swift:31:5: warning: Clone detected (Type 1, 82 tokens, 10 lines, 100.0% similarity)
```

---

## Baseline Workflow

The baseline system lets you acknowledge existing clones and report only newly introduced ones.

### Step 1 — Generate a baseline

Run once on a clean state (e.g. on `main` before introducing a feature):

```bash
swift-cpd --baseline-generate Sources/
# Baseline generated with 5 clone(s) at .swift-cpd-baseline.json
```

Commit `.swift-cpd-baseline.json` to source control.

### Step 2 — Compare against the baseline

On subsequent runs, pass `--baseline` to report only new clones:

```bash
swift-cpd --baseline .swift-cpd-baseline.json Sources/
# Only clones not present in the baseline are printed
```

Exit code is `0` if no new clones are found, `1` if there are new ones.

### Step 3 — Update the baseline

After intentionally accepting new clones (e.g. after a refactor):

```bash
swift-cpd --baseline-update Sources/
# Baseline updated with 7 clone(s) at .swift-cpd-baseline.json
```

### YAML equivalent

```yaml
# .swift-cpd.yml — always compare against the baseline in CI
baseline: .swift-cpd-baseline.json
```

> **Note:** `--baseline-generate` and `--baseline-update` always exit `0`. Use them in a separate step from the comparison run.

---

## Inline Suppression

Suppress specific code regions by adding a comment with the suppression tag immediately before the block or on the line to suppress.

### Block suppression

Suppresses everything inside the following `{...}` block, including nested braces:

```swift
// swiftcpd:ignore
func legacyMigration() {
    // all tokens in this function body are excluded from analysis
    let old = fetchOldRecords()
    let new = transform(old)
    save(new)
}
```

Block comments work too:

```swift
/* swiftcpd:ignore */
class GeneratedMapper {
    // ...
}
```

### Line suppression

When the tag is not immediately before a block, only that line is suppressed:

```swift
let boilerplate = buildGenericHeader() // swiftcpd:ignore
```

### Custom tag

Change the tag in `.swift-cpd.yml` or via CLI to avoid conflicts with other tools:

```yaml
inlineSuppressionTag: cpd:suppress
```

```bash
swift-cpd --suppression-tag "cpd:suppress" Sources/
```

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Check code duplication
  run: swift-cpd --max-duplication 5 --format json --output cpd-report.json Sources/

- name: Upload CPD report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: cpd-report
    path: cpd-report.json
    retention-days: 7
```

### Baseline comparison in pull requests

```yaml
- name: Restore baseline
  run: git show origin/main:.swift-cpd-baseline.json > .swift-cpd-baseline.json || true

- name: Check for new clones
  run: swift-cpd --baseline .swift-cpd-baseline.json Sources/
```

### Quality gate only (no report file)

```bash
# Fail the build if duplication exceeds 3%
swift-cpd --max-duplication 3 Sources/ || {
  echo "Duplication threshold exceeded"
  exit 1
}
```

### SonarQube

Generate a JSON report and point the SonarQube scanner at it:

```yaml
- name: Generate CPD report
  run: swift-cpd --format json --output cpd-report.json Sources/

- name: Run SonarQube scan
  run: sonar-scanner -Dsonar.swift.cpd.reportPaths=cpd-report.json
```

---

## Xcode & SPM Plugin

The `SwiftCPDPlugin` runs `swift-cpd` automatically during the build and surfaces clones as Xcode editor warnings.

### Add to an SPM target

```swift
// Package.swift
.target(
    name: "MyTarget",
    plugins: [.plugin(name: "SwiftCPDPlugin", package: "swift-cpd")]
)
```

### Add to an Xcode target

1. In Xcode, select your target → **Build Phases**
2. Click **+** → **Add Build Tool Plug-in**
3. Select **SwiftCPDPlugin**

The plugin uses `--format xcode` so every clone fragment appears as a yellow warning triangle inline in the source editor.

### Plugin configuration

The plugin respects `.swift-cpd.yml` in the project root. Place the file there and the plugin picks it up automatically on the next build.

To suppress a region in plugin runs:

```swift
// swiftcpd:ignore
func boilerplate() {
    // ...
}
```

---

## Exit Codes

| Code | Constant | Meaning |
|---|---|---|
| `0` | `success` | No clones, or duplication below `maxDuplication` |
| `1` | `clonesDetected` | Clones found (or duplication above threshold) |
| `2` | `configurationError` | Invalid argument, YAML parse error, no paths specified |
| `3` | `analysisError` | Runtime error during analysis (file unreadable, etc.) |

Use exit codes in shell scripts:

```bash
swift-cpd Sources/
case $? in
  0) echo "Clean" ;;
  1) echo "Clones detected — review the report" ;;
  2) echo "Configuration error" ; exit 2 ;;
  3) echo "Analysis failed" ; exit 3 ;;
esac
```
