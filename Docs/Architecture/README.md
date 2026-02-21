# Architecture

## Overview

Swift CPD is a Clone & Pattern Detector for Swift (and optionally C-family languages) that identifies four types of code clones. It follows a **Pipeline (Pipe and Filter)** architecture where each stage receives input from the previous stage and produces output for the next.

```mermaid
flowchart LR
    A[Source Files] --> B[Tokenizer]
    B --> C[Normalizer]
    C --> D[Detector]
    D --> E[Reporter]
```

---

## Project Structure

### Module Dependencies

```mermaid
block-beta
    columns 5

    space:2 ENTRY["SwiftCPD\n@main"]:1 space:2

    space:5

    CLI["CLI"]:1 space:1 CONF["Configuration"]:1 space:1 DISC["FileDiscovery"]:1

    space:5

    space:2 PIPE["Pipeline"]:1 space:2

    space:5

    TOK["Tokenization"]:1 CACHE["Cache"]:1 DET["Detection"]:1 SUPP["Suppression"]:1 BASE["Baseline"]:1

    space:5

    space:2 RPT["Reporting"]:1 space:2

    ENTRY --> CLI
    ENTRY --> CONF
    ENTRY --> DISC
    CLI --> CONF
    DISC --> PIPE
    CONF --> PIPE
    PIPE --> TOK
    PIPE --> CACHE
    PIPE --> DET
    PIPE --> SUPP
    DET --> RPT
    BASE --> RPT
```

### Directory Layout

```text
Sources/SwiftCPD/
├── SwiftCPD.swift                 @main entry point
├── Version.swift
├── CLI/                           Argument parsing and configuration
├── Configuration/                 YAML configuration support
├── FileDiscovery/                 Recursive file discovery
├── Pipeline/                      Pipeline orchestration
├── Tokenization/                  Swift and C-family tokenizers
├── Detection/                     Clone detection algorithms
│   └── SemanticGraph/             Abstract Semantic Graph (Type-4)
├── Reporting/                     Output formatters
├── Cache/                         File-based tokenization cache
├── Baseline/                      Baseline comparison system
└── Suppression/                   Inline suppression scanning
```

### Modules

| Module | Key Types | Responsibility |
|--------|-----------|----------------|
| **CLI** | `ArgumentParser`, `ParsedArguments`, `Configuration`, `HelpText`, `ExitCode`, `OutputFormat` | Parses CLI arguments, merges with YAML config, validates parameters |
| **Configuration** | `YamlConfiguration`, `YamlConfigurationLoader` | Loads `.swift-cpd.yml` configuration files via Yams |
| **FileDiscovery** | `SourceFileDiscovery`, `GlobMatcher` | Recursively finds `.swift` and C-family files, applies exclusion patterns |
| **Pipeline** | `AnalysisPipeline`, `PipelineResult`, `ProgressReporter`, `ProgressState` | Orchestrates tokenization, detection, and caching stages |
| **Tokenization** | `SwiftTokenizer`, `CTokenizer`, `TokenNormalizer`, `UnifiedTokenMapper`, `Token`, `TokenKind`, `SourceLocation` | Tokenizes source code, normalizes tokens, maps cross-language equivalents |
| **Detection** | `CloneDetector`, `Type3Detector`, `Type4Detector`, `CloneGroup`, `CloneFragment`, `CloneType`, `FileTokens`, `CloneGroupBuilder`, `CloneGroupDeduplicator`, `IndexedBlock`, `SignedBlock` | Implements Type-1 through Type-4 clone detection algorithms |
| **Detection/SemanticGraph** | `AbstractSemanticGraph`, `SemanticNode`, `SemanticEdge`, `SemanticNormalizer`, `ASGComparer` | Builds and compares abstract semantic graphs for Type-4 detection |
| **Reporting** | `TextReporter`, `JsonReporter`, `HtmlReporter`, `XcodeReporter`, `AnalysisResult`, `DuplicationCalculator` | Formats analysis results into text, JSON, HTML, or Xcode warnings |
| **Cache** | `FileCache`, `CacheEntry`, `FileHasher` | Actor-based tokenization cache with SHA-256 keying |
| **Baseline** | `BaselineStore`, `BaselineEntry`, `FragmentFingerprint` | Stores known clones for incremental adoption |
| **Suppression** | `SuppressionScanner` | Scans for `// swiftcpd:ignore` comments to suppress regions |

---

## Pipeline Flow

The pipeline has three phases: **Setup**, **Analysis**, and **Output**.

### 1. Setup Phase

Parses CLI arguments, loads optional YAML configuration, discovers source files.

```mermaid
flowchart TD
    A["CLI arguments"] --> B["ArgumentParser"]
    B --> C["ParsedArguments"]
    C --> D["Configuration"]
    E[".swift-cpd.yml"] -.->|optional| D
    D --> F["SourceFileDiscovery"]
    F --> G["File paths"]
```

### 2. Analysis Phase

Tokenizes files in parallel, caches results, runs detection algorithms.

```mermaid
flowchart TD
    A["File paths"] --> B["AnalysisPipeline"]

    B --> C["FileCache.load"]
    C --> D["Tokenize files\n(parallel TaskGroup)"]
    D --> E["FileCache.save"]
    E --> F{"Enabled clone types"}

    F --> G["CloneDetector\nType-1 + Type-2"]
    F --> H["Type3Detector"]
    F --> I["Type4Detector"]

    G --> J["PipelineResult"]
    H --> J
    I --> J
```

### 3. Output Phase

Applies post-detection filters, baseline filtering, formats results, writes output.

```mermaid
flowchart TD
    A["PipelineResult"] --> FILTER["Post-detection filters"]

    FILTER -->|"--ignore-same-file"| FSF["Remove same-file clones"]
    FILTER -->|"--ignore-structural"| FST["Remove Type-3/Type-4 clones"]
    FILTER --> B["AnalysisResult"]

    FSF --> B
    FST --> B

    B --> C{"Baseline mode?"}

    C -->|generate| D["Save baseline"]
    C -->|compare| E["Filter new clones"]
    C -->|none| F["Reporter"]

    E --> F
    D --> G["Exit"]

    F --> H{"Output format"}
    H --> I["Text"]
    H --> J["JSON"]
    H --> K["HTML"]
    H --> L["Xcode"]

    I --> G
    J --> G
    K --> G
    L --> G
```

---

## Tokenization Stage

```mermaid
flowchart TD
    SRC["Source Code"] --> LANG{"Language?"}

    LANG -->|".swift"| ST["SwiftTokenizer\n(SwiftSyntax)"]
    LANG -->|".m .mm .h .c .cpp"| CT["CTokenizer\n(hand-written scanner)"]

    ST --> RAW["Raw tokens"]
    CT --> RAW

    RAW --> CROSS{"Cross-language?"}
    CROSS -->|Yes| UTM["UnifiedTokenMapper"]
    CROSS -->|No| SUPP

    UTM --> SUPP["SuppressionScanner"]
    SUPP --> NORM["TokenNormalizer"]
    NORM --> NORMALIZED["Normalized tokens"]

    RAW --> FT["FileTokens"]
    NORMALIZED --> FT
```

### Token Normalization

The `TokenNormalizer` replaces variable parts of the code with placeholders, enabling detection of structurally identical code with different names or values.

| Token Kind | Example | Normalized |
|------------|---------|------------|
| Identifier | `myVariable` | `$ID` |
| Type Name | `String` | `$TYPE` |
| Integer Literal | `42` | `$NUM` |
| Float Literal | `3.14` | `$NUM` |
| String Literal | `"hello"` | `$STR` |
| Keyword | `func` | `func` (unchanged) |
| Operator | `+` | `+` (unchanged) |
| Punctuation | `{` | `{` (unchanged) |

### Cross-Language Token Mapping

When `--cross-language` is enabled, `UnifiedTokenMapper` maps C/Objective-C tokens to Swift equivalents.

| C/Objective-C | Swift Equivalent |
|----------------|------------------|
| `NSString` | `String` |
| `BOOL` | `Bool` |
| `NSInteger` | `Int` |
| `YES` / `NO` | `true` / `false` |
| `@property` | `var` |
| `[obj method:arg]` | `$CALL` |

---

## Detection Algorithms

```mermaid
flowchart TD
    FT["[FileTokens]"] --> DA{Enabled types?}

    DA -->|Type-1, Type-2| CD[CloneDetector]
    DA -->|Type-3| T3[Type3Detector]
    DA -->|Type-4| T4[Type4Detector]

    CD --> CG1["[CloneGroup]"]
    T3 --> CG2["[CloneGroup]"]
    T4 --> CG3["[CloneGroup]"]

    CG1 --> MERGE["Merge all clone groups"]
    CG2 --> MERGE
    CG3 --> MERGE

    MERGE --> PR[PipelineResult]
```

### Type-1: Exact Clones

Identical code fragments (ignoring whitespace and formatting).

```mermaid
flowchart LR
    A["Raw tokens"] --> B["Rolling hash\n(window = minTokens)"]
    B --> C["Hash table\nlookup"]
    C --> D["Verify exact\ntoken match"]
    D --> E["Expand regions\nforward/backward"]
    E --> F["Deduplicate"]
    F --> G["Filter by\nmin lines"]
```

### Type-2: Parameterized Clones

Structurally identical code with different identifiers, literals, or types.

```mermaid
flowchart LR
    A["Normalized tokens"] --> B["Rolling hash\n(window = minTokens)"]
    B --> C["Hash table\nlookup"]
    C --> D["Verify normalized\ntoken match"]
    D --> E["Expand regions"]
    E --> F["Classify:\nraw match = Type-1\nnormalized only = Type-2"]
    F --> G["Deduplicate"]
```

### Type-3: Gapped Clones

Similar code with insertions, deletions, or modifications.

```mermaid
flowchart TD
    SRC[Source code] --> BE["BlockExtractor\n(SwiftSyntax)"]
    BE --> BLOCKS["[CodeBlock]\nfunctions, methods, closures"]

    BLOCKS --> FP["BlockFingerprint\n(token frequencies)"]
    FP --> JACCARD["Pre-filter:\nJaccard similarity\n(default >= 30%)"]

    JACCARD --> GST["Greedy String Tiling\n(minimum tile = 5 tokens)"]
    GST --> SIM{"Similarity >= threshold?\n(default 70%)"}
    SIM -->|Yes| CLONE[CloneGroup Type-3]
    SIM -->|No| DISCARD[Discard]
```

### Type-4: Semantic Clones

Functionally equivalent code with different implementations.

```mermaid
flowchart TD
    SRC[Source code] --> BE["BlockExtractor"]
    BE --> BLOCKS["[CodeBlock]"]

    BLOCKS --> BSE["BehaviorSignatureExtractor"]
    BLOCKS --> SN["SemanticNormalizer"]

    BSE --> BS["BehaviorSignature\n- Control flow shape\n- Data flow patterns\n- Called functions\n- Type signatures"]

    SN --> ASG["AbstractSemanticGraph\n- Nodes (assignment, call, loop...)\n- Edges (control flow, data flow)"]

    BS --> PRE["Pre-filter:\ncontrol flow shape\nlength ratio >= 30%"]
    PRE --> COMPARE

    BS --> BSC["BehaviorSignatureComparer\n40% control flow (LCS)\n30% data flow\n20% called functions\n10% types"]
    ASG --> ASGC["ASGComparer\n60% node similarity\n40% edge similarity"]

    BSC --> COMPARE["Combined similarity\n0.6 * graph + 0.4 * behavior"]
    ASGC --> COMPARE

    COMPARE --> SIM{"Similarity >= threshold?\n(default 80%)"}
    SIM -->|Yes| CLONE[CloneGroup Type-4]
    SIM -->|No| DISCARD[Discard]
```

### Clone Type Comparison

| Type | Name | Detection Method | Example |
|------|------|------------------|---------|
| Type-1 | Exact | Rolling hash + exact match | Identical copy-pasted code |
| Type-2 | Parameterized | Rolling hash + normalized match | Same structure, different names |
| Type-3 | Gapped | Greedy String Tiling | Similar with insertions/deletions |
| Type-4 | Semantic | ASG + Behavioral Signatures | Different implementation, same logic |

---

## Reporting System

```mermaid
flowchart LR
    AR[AnalysisResult] --> FORMAT{OutputFormat?}
    FORMAT -->|text| TR[TextReporter]
    FORMAT -->|json| JR[JsonReporter]
    FORMAT -->|html| HR[HtmlReporter]
    FORMAT -->|xcode| XR[XcodeReporter]

    TR --> OUT["Human-readable\nsummary + clone list"]
    JR --> OUT2["Structured JSON\nmetadata + summary + clones"]
    HR --> OUT3["Standalone HTML\nwith embedded CSS"]
    XR --> OUT4["Xcode warnings\nfile:line:col: warning:"]
```

### Output Formats

**Text** (default): Human-readable summary with clone locations.

**JSON**: Machine-readable with metadata (configuration, execution time, timestamp), summary (counts by type, duplication percentage), and detailed clone information with code previews.

**HTML**: Standalone page with color-coded clone type badges (Type-1: green, Type-2: blue, Type-3: orange, Type-4: red).

**Xcode**: Warnings in `file:line:column: warning: message` format for Xcode build integration.

---

## Caching System

```mermaid
flowchart TD
    START[Process file] --> HASH["FileHasher\nSHA-256"]
    HASH --> LOOKUP["FileCache.lookup\n(file + hash)"]
    LOOKUP --> HIT{Cache hit?}

    HIT -->|Yes| CACHED["Return cached\ntokens + normalized tokens"]
    HIT -->|No| TOKENIZE["Tokenize + Normalize"]
    TOKENIZE --> STORE["FileCache.store"]
    STORE --> RETURN[Return tokens]

    SAVE["FileCache.save\n.swiftcpd-cache/cache.json"]
```

`FileCache` is an **actor** ensuring thread-safe access from parallel tokenization tasks. The cache persists to `.swiftcpd-cache/cache.json` and is keyed by file path + SHA-256 content hash.

---

## Baseline System

**`--baseline-generate`**

```mermaid
flowchart TD
    A["Current clones"] --> B["Convert to BaselineEntry"]
    B --> C["Save .swiftcpd-baseline.json"]
```

**`--baseline-update`**

```mermaid
flowchart TD
    A["Current clones"] --> B["Overwrite .swiftcpd-baseline.json"]
```

**`--baseline path`**

```mermaid
flowchart TD
    A["Load baseline"] --> B["Convert current clones\nto BaselineEntry set"]
    B --> C["Set subtraction\ncurrent - baseline"]
    C --> D["Report only new clones"]
```

Each `BaselineEntry` contains the clone type, token count, line count, and fragment fingerprints (file + line range). Comparison uses set subtraction to identify clones not present in the baseline.

---

## Concurrency Model

```mermaid
flowchart TD
    MAIN["SwiftCPD.main()"] --> PIPELINE["AnalysisPipeline.analyze()"]

    PIPELINE --> TG["withThrowingTaskGroup"]

    TG --> T1["Task: tokenize file 1"]
    TG --> T2["Task: tokenize file 2"]
    TG --> T3["Task: tokenize file N"]

    T1 --> FC["FileCache (actor)"]
    T2 --> FC
    T3 --> FC

    PIPELINE --> PR["ProgressReporter"]
    PR --> PS["ProgressState (actor)"]
```

| Component | Pattern | Purpose |
|-----------|---------|---------|
| `FileCache` | Actor | Thread-safe tokenization cache |
| `ProgressState` | Actor | Manages cancellable progress task |
| `AnalysisPipeline` | TaskGroup | Parallel file tokenization |
| All data types | Sendable structs/enums | Safe cross-task data sharing |

---

## Configuration Flow

```mermaid
flowchart TD
    CLI["Command-line arguments"] --> AP["ArgumentParser.parse()"]
    AP --> PA["ParsedArguments"]

    YAML[".swift-cpd.yml"] --> YCL["YamlConfigurationLoader"]
    YCL --> YC["YamlConfiguration"]

    PA --> MERGE["Configuration init\nCLI > YAML > defaults"]
    YC --> MERGE

    MERGE --> VALIDATE["validate()\nrange checks"]
    VALIDATE --> CONFIG["Configuration"]

    CONFIG --> DISCOVER["File discovery"]
    CONFIG --> DETECT["Detection thresholds"]
    CONFIG --> REPORT["Output format"]
    CONFIG --> BASE["Baseline mode"]
```

### Default Values

| Parameter | Default | Range |
|-----------|---------|-------|
| `--min-tokens` | 50 | 10 - 500 |
| `--min-lines` | 5 | 2 - 100 |
| `--format` | text | text, json, html, xcode |
| `--type3-similarity` | 70 | 50 - 100 |
| `--type3-tile-size` | 5 | 2 - 20 |
| `--type3-candidate-threshold` | 30 | 10 - 80 |
| `--type4-similarity` | 80 | 60 - 100 |
| `--suppression-tag` | `swiftcpd:ignore` | any string |
| `--types` | 1,2,3,4 | any subset |
| `--ignore-same-file` | `false` | boolean |
| `--ignore-structural` | `false` | boolean |

---

## Inline Suppression

The `SuppressionScanner` allows suppressing clone detection for specific code regions using comments.

```swift
// swiftcpd:ignore
func suppressedFunction() {
    // entire function body is suppressed
}
```

When the scanner finds the suppression tag, it suppresses the following content line. If that line contains `{`, the entire block until the matching `}` is suppressed.
