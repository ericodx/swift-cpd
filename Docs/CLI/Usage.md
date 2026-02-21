# CLI Usage

Examples of how to use the `swift-cpd` command-line tool.

For the full list of options, run `swift-cpd --help`.

---

## Initialize Configuration

Generate a default `.swift-cpd.yml` in the current directory:

```bash
swift-cpd init
```

This creates a configuration file with sensible defaults. If `.swift-cpd.yml` already exists, the command exits with an error.

---

## Basic Usage

Analyze a single directory:

```bash
swift-cpd Sources/
```

Analyze multiple paths:

```bash
swift-cpd Sources/ OtherModule/
```

Analyze a single file:

```bash
swift-cpd Sources/MyApp/ViewController.swift
```

---

## Output Formats

### Text (default)

```bash
swift-cpd --format text Sources/
```

### JSON

```bash
swift-cpd --format json Sources/
```

### HTML

```bash
swift-cpd --format html --output report.html Sources/
```

### Xcode Warnings

```bash
swift-cpd --format xcode Sources/
```

---

## Writing Output to File

```bash
swift-cpd --output duplicated-code.txt Sources/

swift-cpd --format json --output duplicated-code.json Sources/

swift-cpd --format html --output duplicated-code.html Sources/
```

---

## Detection Thresholds

### Minimum Token Count

Only report clones with at least 100 tokens (default: 50):

```bash
swift-cpd --min-tokens 100 Sources/
```

### Minimum Line Count

Only report clones with at least 10 lines (default: 5):

```bash
swift-cpd --min-lines 10 Sources/
```

### Combine Thresholds

```bash
swift-cpd --min-tokens 80 --min-lines 8 Sources/
```

---

## Clone Type Selection

By default, all four types are enabled. Use `--types` to restrict to a subset, or `--types all` to explicitly enable all.

Explicitly enable all types:

```bash
swift-cpd --types all Sources/
```

Detect only exact and parameterized clones:

```bash
swift-cpd --types 1,2 Sources/
```

Detect only gapped and semantic clones:

```bash
swift-cpd --types 3,4 Sources/
```

Detect only exact clones:

```bash
swift-cpd --types 1 Sources/
```

---

## Type-3 Tuning

Lower the similarity threshold to catch more gapped clones (default: 70):

```bash
swift-cpd --type3-similarity 60 Sources/
```

Increase the candidate pre-filter for faster analysis on large codebases (default: 30):

```bash
swift-cpd --type3-candidate-threshold 50 Sources/
```

Adjust the minimum tile size for Greedy String Tiling (default: 5):

```bash
swift-cpd --type3-tile-size 3 Sources/
```

Combine Type-3 options:

```bash
swift-cpd --type3-similarity 65 --type3-tile-size 4 --type3-candidate-threshold 40 Sources/
```

---

## Type-4 Tuning

Lower the semantic similarity threshold to catch more semantic clones (default: 80):

```bash
swift-cpd --type4-similarity 70 Sources/
```

---

## Excluding Files

Exclude test files:

```bash
swift-cpd --exclude "*Tests*" Sources/
```

Exclude generated code:

```bash
swift-cpd --exclude "*.generated.swift" Sources/
```

Multiple exclusions:

```bash
swift-cpd --exclude "*Tests*" --exclude "*Mock*" --exclude "*.generated.swift" Sources/
```

Exclude a specific directory:

```bash
swift-cpd --exclude "**/Generated/**" Sources/
```

---

## Inline Suppression

Suppress detection for a specific block by adding a comment in your source code:

```swift
// swiftcpd:ignore
func knownDuplicate() {
    // this function will be ignored
}
```

Use a custom suppression tag:

```bash
swift-cpd --suppression-tag "cpd:skip" Sources/
```

Then in your code:

```swift
// cpd:skip
func skippedFunction() { ... }
```

---

## Baseline

### Generate a Baseline

Save current clones as a baseline (creates `.swiftcpd-baseline.json`):

```bash
swift-cpd --baseline-generate Sources/
```

### Compare Against Baseline

Report only new clones not in the baseline:

```bash
swift-cpd --baseline .swiftcpd-baseline.json Sources/
```

### Update the Baseline

Overwrite the baseline with current clones:

```bash
swift-cpd --baseline-update Sources/
```

### Custom Baseline Path

```bash
swift-cpd --baseline-generate --baseline my-baseline.json Sources/
```

---

## Maximum Duplication Threshold

Fail with exit code 1 if duplication exceeds 5%:

```bash
swift-cpd --max-duplication 5 Sources/
```

Useful in CI pipelines to enforce duplication limits.

---

## Filtering Clones

### Ignore Same-File Clones

Exclude clones where all fragments belong to the same file:

```bash
swift-cpd --ignore-same-file Sources/
```

This is useful when you only want to detect cross-file duplication and ignore internal repetitions within a single file.

### Ignore Structural Clones

Exclude Type-3 (gapped) and Type-4 (semantic) clones from the output, keeping only Type-1 (exact) and Type-2 (parameterized):

```bash
swift-cpd --ignore-structural Sources/
```

Structural clones often represent domain-inherent similarity (e.g., similar pipeline stages, I/O patterns) rather than actual copy-paste duplication. This flag filters them from the results without changing detection — all four types are still detected internally, but Type-3 and Type-4 are excluded from the report.

### Combine Filters

```bash
swift-cpd --ignore-same-file --ignore-structural Sources/
```

---

## Cross-Language Detection

Detect clones across Swift and Objective-C/C files:

```bash
swift-cpd --cross-language Sources/
```

This maps Objective-C types and patterns to Swift equivalents before comparison.

---

## YAML Configuration

Use a configuration file instead of CLI flags:

```bash
swift-cpd --config .swift-cpd.yml
```

Example `.swift-cpd.yml`:

```yaml
paths:
  - Sources/
minimumTokenCount: 50
minimumLineCount: 5
outputFormat: text
type3Similarity: 70
type4Similarity: 80
crossLanguageEnabled: false
ignoreSameFile: false
ignoreStructural: false
exclude:
  - "*Tests*"
  - "*.generated.swift"
enabledCloneTypes:
  - 1
  - 2
  - 3
```

CLI flags override YAML values when both are provided.

---

## CI/CD Examples

### GitHub Actions

```yaml
- name: Check duplication
  run: swift-cpd --max-duplication 5 --format text Sources/
```

### With Baseline

```yaml
- name: Check new clones
  run: swift-cpd --baseline .swiftcpd-baseline.json --format text Sources/
```

### JSON Report as Artifact

```yaml
- name: Generate report
  run: swift-cpd --format json --output cpd-report.json Sources/

- name: Upload report
  uses: actions/upload-artifact@v4
  with:
    name: cpd-report
    path: cpd-report.json
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No clones detected (or baseline/report generated successfully) |
| `1` | Clones detected (or max duplication exceeded) |
| `2` | Configuration error (invalid arguments or config) |
| `3` | Analysis error (runtime failure) |
