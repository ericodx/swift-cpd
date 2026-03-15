## Summary

<!-- What does this change do? Keep it concise. -->

## Type of Change

- [ ] feat: A new feature has been added.
- [ ] fix: A bug has been fixed.
- [ ] perf: A code change that improves performance.
- [ ] refactor: A code change that neither fixes a bug nor adds a feature.
- [ ] test: Addition or correction of tests.
- [ ] docs: Changes only to the documentation.
- [ ] ci: Changes related to continuous integration and deployment scripts.
- [ ] build: Changes that affect the build system or external dependencies.
- [ ] chore: Other changes that do not fit into the previous categories.
- [ ] revert: Reverts a previous commit.

## Invariants Checklist

- [ ] Detection is deterministic (same input → same output)
- [ ] Source files are never modified (tool is read-only)
- [ ] Source locations are accurate (file, line, column)
- [ ] No false negatives introduced (previously detected clones are still detected)
- [ ] Performance not degraded for large codebases
- [ ] Swift 6 Strict Concurrency compatible
- [ ] Pipeline stages remain stateless pure transformations

## Pipeline Impact

Which stages are affected?

- [ ] FileDiscovery
- [ ] Tokenization
- [ ] Normalization
- [ ] Detection (Type 1 / Type 2 / Type 3 / Type 4)
- [ ] Reporting
- [ ] CLI / Configuration
- [ ] Cache / Baseline
- [ ] None

## Testing

- [ ] Unit tests added or updated
- [ ] Tests use `TokenFactory` / `TempFileHelper` / `AnalysisHelper` where appropriate
- [ ] Integration tests added or updated (if detection or pipeline logic changed)
- [ ] Both positive cases (expected clones) and negative cases (false positives to avoid) covered
- [ ] All tests pass locally (`swift test`)
