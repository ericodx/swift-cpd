# CI

GitHub Actions workflows for Swift CPD.

---

## Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `pull-request-analysis.yml` | Pull requests to `main` | Tests, coverage, static analysis, quality gate |
| `main-analysis.yml` | Push to `main` | Full analysis with SonarCloud reporting |
| `release.yml` | Tag push (`v*`) | Build, package, and publish release |

---

## Pull Request Pipeline

```text
test-and-coverage
        │
        ▼
static-analysis
        │
        ▼
  quality-gate ──► PR comment
```

### Jobs

| Job | Runner | Description |
|-----|--------|-------------|
| `test-and-coverage` | `macos-26` | Runs tests, generates coverage, uploads `swift-cpd` binary |
| `static-analysis` | `macos-26` | SwiftLint, Periphery, Gitleaks, swift-cpd duplication check |
| `quality-gate` | `ubuntu-latest` | Evaluates thresholds and posts quality report to PR |

### Quality Gate Thresholds

Thresholds are configured via GitHub repository variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `COVERAGE_THRESHOLD` | `95` | Minimum line coverage percentage |
| `MAX_DUPLICATION` | `5` | Maximum duplication percentage |
| `MAX_LINT_VIOLATIONS` | `10` | Maximum SwiftLint violations |
| `MAX_DEAD_CODE` | `0` | Maximum dead code instances |
| `FAIL_ON_SECRETS` | `true` | Fail if secrets are detected |
| `STRICT_MODE` | `false` | Enforce all thresholds as hard failures |

---

## Release Pipeline

```text
tag push (v*) ──► inject version ──► build ──► archive ──► GitHub Release
```

The release workflow injects the tag version into `Version.swift`, replacing `0.0.0-dev` with the actual version number.

---

## Using swift-cpd in Your CI

### Basic Check

```yaml
- name: Check duplication
  run: swift-cpd --max-duplication 5 --format text Sources/
```

### With Baseline

```yaml
- name: Check for new duplications
  run: swift-cpd --baseline .swiftcpd-baseline.json --format xcode Sources/
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

## Next Steps

| Document | Description |
|----------|-------------|
| [CLI Usage](../CLI/Usage.md) | Commands, flags, and configuration |
| [Xcode Plugin](../Integration/XcodePlugin.md) | Build tool plugin setup |
