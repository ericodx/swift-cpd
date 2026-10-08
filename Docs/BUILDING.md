# Building from Source

## Prerequisites

- macOS 15 or later
- Xcode 26 or later
- Swift 6.2 or later

## Clone and Build

```bash
git clone https://github.com/ericodx/swift-cpd.git
cd swift-cpd
swift build
```

For an optimized release build:

```bash
swift build -c release
```

The binary will be at `.build/release/swift-cpd`.

## Run Tests

```bash
swift test
```

With code coverage:

```bash
swift test --enable-code-coverage
```

## Make Targets

The `Makefile` mirrors the CI jobs in `.github/workflows/main-analysis.yml`:

| Target | Description |
|---|---|
| `make test` | Run unit tests (`swift test`) |
| `make coverage` | Run tests with coverage and write `coverage/lcov.info` and `coverage/code-coverage-report.xml` |
| `make sonar` | Build coverage, then upload to SonarCloud (requires `SONAR_TOKEN` and `sonar-scanner`) |
| `make clean` | Remove `.build` and coverage artifacts |

Run `make help` to list the targets.

## Install Locally

After building in release mode, copy the binary to a directory in your `$PATH`:

```bash
cp .build/release/swift-cpd /usr/local/bin/
```

## Run Without Installing

```bash
swift run swift-cpd
```

Generate a configuration file and run the detector:

```bash
swift run swift-cpd init
swift run swift-cpd
```
