# Xcode Plugin Installation Guide

`SwiftCPDPlugin` integrates clone detection directly into the Xcode build system. After installation, every build runs `swift-cpd` automatically and surfaces clones as **yellow warning triangles** inline in the source editor — no terminal required.

---

## Table of Contents

1. [How it works](#how-it-works)
2. [Installing in an Xcode project](#installing-in-an-xcode-project)
3. [Installing in an SPM package](#installing-in-an-spm-package)
4. [First build](#first-build)
5. [Configuring the plugin](#configuring-the-plugin)
6. [Suppressing warnings](#suppressing-warnings)
7. [Removing the plugin](#removing-the-plugin)
8. [Troubleshooting](#troubleshooting)

---

## How it works

The plugin is a **build tool plugin**: Xcode runs it as a build phase before compiling. It invokes `swift-cpd` with the `--format xcode` flag, which produces one line per clone fragment in the format Xcode's build system recognises as a diagnostic:

```
/path/to/File.swift:42:1: warning: Clone detected (Type 2, 120 tokens, 15 lines, 100.0% similarity)
```

A small empty marker file is written to the plugin's work directory so Xcode knows the command completed. On subsequent builds, Xcode skips the plugin if no source files changed (incremental build support).

---

## Installing in an Xcode project

This path applies to standard `.xcodeproj` projects — apps, frameworks, and extensions built with Xcode.

### Step 1 — Add the swift-cpd package

Open your project in Xcode, then:

1. **File → Add Package Dependencies…**
2. In the search bar, paste the repository URL:
   ```
   https://github.com/ericodx/swift-cpd
   ```
3. Choose a version rule (e.g. **Up to Next Major Version**) and click **Add Package**.
4. When Xcode asks which products to add to your target, select **SwiftCPDPlugin** and click **Add Package**.

> Xcode will clone the package and compile `swift-cpd` the first time. This takes a minute or two.

### Step 2 — Add the plugin to your target

If the plugin was not automatically added to a target in Step 1:

1. Select your project in the **Project Navigator**.
2. Select the **target** you want to analyze.
3. Go to the **Build Phases** tab.
4. If a **Run Build Tool Plug-ins** phase already exists (e.g. from another plugin), click **+** inside it and select **SwiftCPDPlugin**. If the phase does not exist yet, click **+** at the top-left of the Build Phases tab → **Add Build Tool Plug-in…** → select **SwiftCPDPlugin** and click **Add**.

Repeat for each target you want to monitor.

### Step 3 — Trust the plugin

The first time you build after adding the plugin, Xcode will show a permission dialog:

> *"SwiftCPDPlugin" wants permission to read and write to your project's source directory.*

Click **Trust & Enable** to allow the plugin to run. This prompt appears once per project.

### Step 4 — Build

Press **⌘B**. Xcode runs the plugin as part of the build. When the build finishes, any detected clones appear in the **Issue Navigator** (⌘5) and as warning annotations in the editor.

---

## Installing in an SPM package

This path applies to `Package.swift`-based projects — libraries, command-line tools, and SwiftPM apps.

### Step 1 — Add the dependency

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ericodx/swift-cpd", from: "1.0.0"),
],
```

### Step 2 — Add the plugin to a target

```swift
targets: [
    .target(
        name: "MyLibrary",
        dependencies: [...],
        plugins: [
            .plugin(name: "SwiftCPDPlugin", package: "swift-cpd")
        ]
    ),
]
```

The plugin is applied per-target. Add it to every target you want to monitor.

### Step 3 — Build

```bash
swift build
```

Clone warnings are printed to the terminal in the Xcode diagnostic format. When opened in Xcode, they appear as inline editor warnings.

---

## First build

The first build after installation takes longer than usual because:

1. Xcode resolves and downloads the `swift-cpd` package (~30 seconds, network dependent).
2. Xcode compiles `swift-cpd` and its `swift-syntax` dependency (~1–2 minutes).
3. `swift-cpd` analyzes your source files for the first time and writes the token cache.

Subsequent builds are fast. The plugin is skipped entirely when no source files have changed. When files do change, only the analysis step runs — the tool binary is already compiled and the cache is warm.

---

## Configuring the plugin

The plugin respects a `.swift-cpd.yml` file placed in the **project root** (the directory that contains your `.xcodeproj` or `Package.swift`).

Generate a starter config:

```bash
swift-cpd init
```

Then edit `.swift-cpd.yml` to suit your project. The most common adjustments when running through the plugin:

```yaml
# Exclude test targets — they often have intentional duplication
exclude:
  - "**/*Tests*"
  - "**/*Spec*"
  - "**/Preview Content/**"

# Type 1 and 2 are fast and have no false positives — good default for CI
enabledCloneTypes:
  - 1
  - 2

# Ignore clones that are entirely within one file
ignoreSameFile: true

# Raise the bar slightly to reduce noise from short repeated patterns
minimumTokenCount: 70
minimumLineCount: 7
```

> **Note:** The plugin analyzes the entire project directory (`context.xcodeProject.directoryURL`). The `exclude:` list is the primary way to restrict the scope to your own source code.

---

## Suppressing warnings

### Suppress a whole block

Add a comment with the suppression tag on the line immediately before the opening brace:

```swift
// swiftcpd:ignore
func setupLegacyBridge() {
    // all code inside this function is excluded from analysis
    legacyInit()
    legacyBind()
    legacyStart()
}
```

### Suppress a single line

```swift
let generated = TemplateFactory.makeBoilerplate() // swiftcpd:ignore
```

### Suppress a generated file entirely

Use the `exclude:` list in `.swift-cpd.yml`:

```yaml
exclude:
  - "**/Generated/**"
  - "**/*.generated.swift"
  - "**/R.generated.swift"
```

### Custom suppression tag

If `swiftcpd:ignore` conflicts with another tool, change it in `.swift-cpd.yml`:

```yaml
inlineSuppressionTag: "cpd:ignore"
```

---

## Removing the plugin

### From an Xcode project

1. Select your project in the **Project Navigator**.
2. Select the **target**.
3. Go to **Build Phases**.
4. Find the **Run Build Tool Plug-ins** phase, select **SwiftCPDPlugin**, and click **–**.
5. To also remove the package: go to **File → Packages → Reset Package Caches**, then remove `swift-cpd` from **Project → Package Dependencies**.

### From a Package.swift project

Remove the `.plugin(...)` entry from the target, and optionally remove the `.package(...)` dependency:

```swift
// Remove this line from the target:
.plugin(name: "SwiftCPDPlugin", package: "swift-cpd")

// Remove this line from dependencies: if no longer needed:
.package(url: "https://github.com/ericodx/swift-cpd", from: "1.0.0"),
```

---

## Troubleshooting

### No warnings appear after building

- Confirm the plugin is listed under **Build Phases → Run Build Tool Plug-ins** for the target.
- Check the **Report Navigator** (⌘9) → last build → expand **SwiftCPD: Detecting clones** to see if the tool ran and what it output.
- Verify that `.swift-cpd.yml` does not exclude your source directory via `exclude:` patterns.
- Check that `enabledCloneTypes` is not empty.

### "Plugin not found" or "tool not found" error

Xcode must compile `swift-cpd` before it can run the plugin. Try:

1. **File → Packages → Reset Package Caches**
2. **Product → Clean Build Folder** (⇧⌘K)
3. Build again.

### Plugin runs but finds nothing (project too small)

By default, `minimumTokenCount: 50` and `minimumLineCount: 5` require non-trivial duplication. Small projects or projects with short functions may not produce any results. Try lowering the thresholds temporarily:

```yaml
minimumTokenCount: 30
minimumLineCount: 3
```

### Warnings appear in unexpected files

The Xcode plugin passes the entire project directory to `swift-cpd`. Use `exclude:` patterns in `.swift-cpd.yml` to narrow the scope:

```yaml
exclude:
  - "**/Pods/**"
  - "**/Carthage/**"
  - "**/.build/**"
  - "**/DerivedData/**"
```

### Build is slow after every change

Ensure your `.swift-cpd.yml` is in the project root so the cache is reused across builds. If the cache directory is being cleaned (e.g. by a `Clean Build Folder`), this is expected — the cache will be warm again after the next build.
