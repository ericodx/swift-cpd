# Plugin

Swift Package Manager Build Tool Plugin for Xcode integration.

## Files

- `Plugins/SwiftCPDPlugin/SwiftCPDPlugin.swift`

---

## SwiftCPDPlugin

`struct SwiftCPDPlugin: BuildToolPlugin` (`@main`)

A **prebuild command** plugin that runs `swift-cpd` automatically before each build. Integrates with Xcode to show clone warnings inline.

### Behavior

- Runs before compilation of each source target
- Uses `--format xcode` to produce Xcode-compatible warnings
- Analyzes the target's source directory
- Output directory is the plugin's work directory

### Usage

Add the plugin to a target in `Package.swift`:

```swift
.target(
    name: "MyTarget",
    plugins: [
        .plugin(name: "SwiftCPDPlugin", package: "SwiftCPD")
    ]
)
```

### Method

| Method | Signature |
|---|---|
| `createBuildCommands` | `(context: PluginContext, target: Target) async throws -> [Command]` |

The method returns a single `.prebuildCommand` that invokes the `swift-cpd` executable with the target's directory path and xcode output format.
