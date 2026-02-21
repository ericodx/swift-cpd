# Xcode Integration

Guide for integrating SwiftCPD into your Xcode workflow.

---

## Build Tool Plugin (Recommended)

The Build Tool Plugin provides native Xcode integration with zero configuration. Warnings appear inline in the editor during builds.

### Swift Package Manager Projects

Add the plugin to your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/ericodx/swift-cpd.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MyApp",
            plugins: [
                .plugin(name: "SwiftCPDPlugin", package: "swift-cpd")
            ]
        ),
    ]
)
```

### Xcode Projects (.xcodeproj)

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter: `https://github.com/ericodx/swift-cpd`
3. Select your target → **Build Phases** tab
4. Expand **Run Build Tool Plug-ins**
5. Click **+** and add **SwiftCPDPlugin**

### How It Works

The plugin runs `swift-cpd --format xcode` during each build:

- Analyzes all Swift files in the target
- Reports warnings inline in the Xcode editor
- Does not fail the build (warnings only)
- Uses `.swift-cpd.yml` if present in the project root

### Limitations

Due to SPM sandbox restrictions, the plugin writes its cache to DerivedData instead of the project directory. This is handled automatically.

### Trust the Plugin

On first build, Xcode or SPM will ask you to trust the plugin. Select **Trust & Enable All** to allow it to run.

In SPM, use the `--allow-writing-to-package-directory` flag if prompted:

```bash
swift build --allow-writing-to-package-directory
```

### Multiple Targets

Apply the plugin to each target individually:

```swift
targets: [
    .target(
        name: "Core",
        plugins: [.plugin(name: "SwiftCPDPlugin", package: "swift-cpd")]
    ),
    .target(
        name: "Networking",
        plugins: [.plugin(name: "SwiftCPDPlugin", package: "swift-cpd")]
    ),
]
```

Each target is analyzed independently.

---

## Build Phase (Alternative)

For more control over execution, add a Run Script Build Phase.

### Setup Steps

1. Select your project in Xcode
2. Select your target
3. Go to **Build Phases**
4. Click **+** → **New Run Script Phase**
5. Name it "SwiftCPD Check"
6. Add the script below

### Check Script (Warning on Issues)

```bash
export PATH="/opt/homebrew/bin:$PATH"

if command -v swift-cpd >/dev/null; then
    swift-cpd --format xcode "${SRCROOT}/Sources"
else
    echo "warning: swift-cpd not installed"
fi
```

The `--format xcode` flag outputs warnings in Xcode-compatible format and does not fail the build.

### Build Phase Position

Place the script phase after "Compile Sources" for minimal build impact:

```
┌─────────────────────────────┐
│ Target Dependencies         │
├─────────────────────────────┤
│ Compile Sources             │
├─────────────────────────────┤
│ SwiftCPD Check              │  ← Check here
├─────────────────────────────┤
│ Link Binary With Libraries  │
└─────────────────────────────┘
```

---

## Configuration

The plugin runs with default settings. To customize thresholds and options, create a `.swift-cpd.yml` file in your project root:

```yaml
minimumTokenCount: 50
minimumLineCount: 5
type3Similarity: 70
type4Similarity: 80
exclude:
  - "*.generated.swift"
```

See [CLI Usage](../CLI/Usage.md) for all available options.

---

## Troubleshooting

### "swift-cpd: command not found"

Xcode Build Phases use `/bin/sh` and do not load your shell profile, so Homebrew commands are not in the PATH.

**Solution:** Add Homebrew to PATH at the start of your script:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```

### Build Phase Not Running

1. Uncheck "Based on dependency analysis"
2. Remove input/output files if specified
3. Verify script has correct permissions

---

## Next Steps

| Document | Description |
|----------|-------------|
| [Installation](../INSTALLATION.md) | CLI installation methods |
| [CLI Usage](../CLI/Usage.md) | Running analysis from the command line |
