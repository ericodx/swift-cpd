# Installation

---

## Homebrew (Recommended)

```bash
brew tap ericodx/homebrew-tools
brew install swift-cpd
```

### Update

```bash
brew upgrade swift-cpd
```

### Verify

```bash
swift-cpd --version
```

---

## Build from Source

### Requirements

- **macOS** 15 or later
- **Swift** 6.2 or later

### Steps

1. Clone the repository:

```bash
git clone https://github.com/ericodx/swift-cpd.git
cd swift-cpd
```

2. Build in release mode:

```bash
swift build -c release
```

3. Copy the binary to your PATH:

```bash
cp .build/release/swift-cpd /usr/local/bin/
```

4. Verify:

```bash
swift-cpd --version
```

---

## Swift Package Manager

Add as a dependency in your `Package.swift`:

```swift
.package(url: "https://github.com/ericodx/swift-cpd.git", from: "1.0.0")
```

See [Xcode Plugin](Integration/XcodePlugin.md) for build tool plugin setup.

---

## Next Steps

| Document | Description |
|----------|-------------|
| [CLI Usage](CLI/Usage.md) | Commands, flags, and examples |
| [Xcode Plugin](Integration/XcodePlugin.md) | Build tool plugin integration |
