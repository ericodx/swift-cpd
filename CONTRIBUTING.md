# Contributing to Swift Clone & Pattern Detector

Thank you for your interest in contributing to **Swift Clone & Pattern Detector**.

Swift Clone & Pattern Detector is a native Swift tool for detecting duplicate code with Xcode integration. It analyzes Swift source files to identify Type-1 (exact) and Type-2 (parameterized) code clones.

For an overview of the project goals and scope, see the [README](README.md).

---

## Code of Conduct

Be respectful, professional, and constructive in all interactions.
This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

---

## Technical Principles

Swift Clone & Pattern Detector follows a strict set of technical principles:

- Detection must be **deterministic and reproducible**
- The tool is **read-only** — it never modifies source files
- Results must include **precise source locations** (file, line, column)
- Performance matters — the tool must scale to large codebases
- **Zero external dependencies** beyond SwiftSyntax
- Full compatibility with **Swift 6 Strict Concurrency**

Changes that violate these principles will not be accepted, even if they pass tests.

---

## AI-Assisted Contributions

AI-assisted contributions are welcome.

When using tools such as GitHub Copilot or other LLMs:

- Treat AI as an **assistant**, not an authority
- Ensure all generated code follows the same standards as human-written code
- Prefer **validation over transformation**
- Do not introduce speculative or inferred behavior

Follow the same code review standards regardless of how the code was written.

---

## Pull Requests

All Pull Requests must:

- Follow the repository PR template
- Be focused on a single concern
- Reference an existing issue when applicable
- Respect the technical principles described above

AI-generated changes are reviewed under the same criteria as human-written code.

---

## Workflow

1. Open an issue describing the problem or proposal
2. Wait for maintainer feedback
3. Implement the change in a focused branch
4. Open a Pull Request referencing the issue

Unapproved structural changes may be closed without review.

---

## Testing

- Unit tests are mandatory for all new functionality
- Integration tests with real Swift files are required for detection logic
- Tests must prove **determinism** — same input always produces same output
- Include both positive cases (expected clones) and negative cases (false positives to avoid)
- Target code coverage: **90%+**

---

## Communication

All communication happens publicly via GitHub Issues and Discussions.
Private contact is discouraged.

---

## License

By contributing, you agree that your contributions are licensed under the [BSD 3-Clause License](./LICENSE).
