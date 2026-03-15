# Installation

## Requirements

- macOS 15 or later
- Xcode 16 or later (for building from source or using the Xcode plugin)
- Swift 6.2 or later (for building from source)

---

## Homebrew (recommended)

The fastest way to install `swift-cpd` on macOS.

```bash
brew tap ericodx/homebrew-tools
brew install swift-cpd
```

Verify the installation:

```bash
swift-cpd --version
# swift-cpd 1.0.0 [arm64-macos15]
```

### Updating

```bash
brew upgrade swift-cpd
```

### Uninstalling

```bash
brew uninstall swift-cpd
brew untap ericodx/homebrew-tools  # optional
```

---

## Download a pre-built binary

Pre-built binaries are published with every release on the [GitHub Releases page](https://github.com/ericodx/swift-cpd/releases).

```bash
# Replace X.Y.Z with the desired version
VERSION="1.0.0"
curl -L "https://github.com/ericodx/swift-cpd/releases/download/v${VERSION}/swift-cpd-v${VERSION}-macos.tar.gz" \
  | tar -xz

# Move to a directory in your PATH
sudo mv swift-cpd /usr/local/bin/
```

Verify:

```bash
swift-cpd --version
```

---

## Build from source

Requires Swift 6.2 or later. Check your version with `swift --version`.

```bash
git clone https://github.com/ericodx/swift-cpd.git
cd swift-cpd
swift build -c release
```

The compiled binary is at `.build/release/swift-cpd`. Copy it to a directory in your `PATH`:

```bash
sudo cp .build/release/swift-cpd /usr/local/bin/
```

---

## Run without installing (SPM)

If your project already uses Swift Package Manager you can run `swift-cpd` directly without a global install:

```bash
# From the swift-cpd repository root
swift run swift-cpd Sources/

# Or point to the package from another directory
swift run --package-path /path/to/swift-cpd swift-cpd Sources/
```

---

## pre-commit hook

`swift-cpd` can run automatically on every `git commit` via [pre-commit](https://pre-commit.com), blocking the commit if new clones are introduced.

### Step 1 — Install pre-commit

```bash
brew install pre-commit
```

### Step 2 — Add the hook to your project

Create or edit `.pre-commit-config.yaml` in your repository root:

```yaml
repos:
  - repo: https://github.com/ericodx/swift-cpd
    rev: v1.0.0   # replace with the desired version tag
    hooks:
      - id: swift-cpd
```

### Step 3 — Install the hook

```bash
pre-commit install
```

From this point on, `swift-cpd` runs automatically whenever you `git commit`. If clones are detected the commit is blocked and the report is printed to the terminal.

### Running manually

```bash
pre-commit run swift-cpd          # run on staged files only
pre-commit run swift-cpd --all-files  # run on the entire repository
```

### Configuration

The hook respects `.swift-cpd.yml` in the repository root. Place your configuration there to control thresholds, excluded paths, and enabled clone types. See the [Usage & Configuration Guide](usage.md) for all available options.

> **Note:** The hook uses `pass_filenames: false` — it always analyzes the paths defined in `.swift-cpd.yml` (or the default discovery), not just the files staged for the commit.

---

## Xcode & SPM plugin

The plugin integrates clone detection into the Xcode build system — no CLI installation required. See the [Xcode Plugin Installation Guide](xcode-plugin.md) for step-by-step instructions.

---

## Verify the installation

```bash
swift-cpd --version   # print version and platform
swift-cpd --help      # print all available options
swift-cpd init        # generate a starter .swift-cpd.yml in the current directory
```
