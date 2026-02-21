enum HelpText {

    static var usage: String {
        """
        USAGE: swift-cpd [options] <paths...>
               swift-cpd init

        COMMANDS:
          init                   Generate a default .swift-cpd.yml configuration file

        OPTIONS:
          --min-tokens <N>       Minimum token count for clone detection (default: 50)
          --min-lines <N>        Minimum line count for clone detection (default: 5)
          --format <format>      Output format: text, json, html, xcode (default: text)
          --output <path>        Write output to file instead of stdout
          --baseline-generate    Generate baseline file from current clones
          --baseline-update      Update existing baseline with current clones
          --baseline <path>      Baseline file path (default: .swiftcpd-baseline.json)
          --config <path>        Path to YAML configuration file (default: .swift-cpd.yml)
          --max-duplication <N>  Maximum duplication percentage (0-100) before failing
          --type3-similarity <N> Type-3 similarity threshold in percent (default: 70)
          --type3-tile-size <N>  Type-3 minimum tile size (default: 5)
          --type3-candidate-threshold <N>
                                 Type-3 candidate filter threshold in percent (default: 30)
          --type4-similarity <N> Type-4 semantic similarity threshold in percent (default: 80)
          --types <1,2,3,4|all>  Clone types to detect (default: all)
          --exclude <pattern>    Exclude files matching glob pattern (repeatable)
          --suppression-tag <tag>
                                 Inline suppression tag (default: swiftcpd:ignore)
          --ignore-same-file     Ignore clones where all fragments are in the same file
          --ignore-structural    Ignore Type-3 and Type-4 clones (structural similarity)
          --cross-language       Enable cross-language detection (Swift + Objective-C/C)
          --version              Show version information
          --help                 Show this help message
        """
    }
}
