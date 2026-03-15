import Testing

@testable import swift_cpd

@Suite("ArgumentParser")
struct ArgumentParserTests {

    let parser = ArgumentParser()

    @Test("Given positional arguments, when parsing, then captures them as paths")
    func positionalPaths() throws {
        let result = try parser.parse(["swift-cpd", "Sources/", "Tests/"])

        #expect(result.paths == ["Sources/", "Tests/"])
    }

    @Test("Given --version flag, when parsing, then showVersion is true")
    func versionFlag() throws {
        let result = try parser.parse(["swift-cpd", "--version"])

        #expect(result.showVersion == true)
    }

    @Test("Given --help flag, when parsing, then showHelp is true")
    func helpFlag() throws {
        let result = try parser.parse(["swift-cpd", "--help"])

        #expect(result.showHelp == true)
    }

    @Test("Given --min-tokens with value, when parsing, then captures token count")
    func minTokensFlag() throws {
        let result = try parser.parse(["swift-cpd", "--min-tokens", "30", "Sources/"])

        #expect(result.minimumTokenCount == 30)
        #expect(result.paths == ["Sources/"])
    }

    @Test("Given --min-lines with value, when parsing, then captures line count")
    func minLinesFlag() throws {
        let result = try parser.parse(["swift-cpd", "--min-lines", "3", "Sources/"])

        #expect(result.minimumLineCount == 3)
    }

    @Test("Given --format text, when parsing, then captures text format")
    func formatTextFlag() throws {
        let result = try parser.parse(["swift-cpd", "--format", "text", "Sources/"])

        #expect(result.format == .text)
    }

    @Test("Given --format json, when parsing, then captures json format")
    func formatJsonFlag() throws {
        let result = try parser.parse(["swift-cpd", "--format", "json", "Sources/"])

        #expect(result.format == .json)
    }

    @Test("Given --format xcode, when parsing, then captures xcode format")
    func formatXcodeFlag() throws {
        let result = try parser.parse(["swift-cpd", "--format", "xcode", "Sources/"])

        #expect(result.format == .xcode)
    }

    @Test("Given --output with path, when parsing, then captures output file path")
    func outputFlag() throws {
        let result = try parser.parse(["swift-cpd", "--output", "report.html", "Sources/"])

        #expect(result.outputFilePath == "report.html")
    }

    @Test("Given --baseline-generate flag, when parsing, then baselineGenerate is true")
    func baselineGenerateFlag() throws {
        let result = try parser.parse(["swift-cpd", "--baseline-generate", "Sources/"])

        #expect(result.baselineGenerate == true)
    }

    @Test("Given --baseline-update flag, when parsing, then baselineUpdate is true")
    func baselineUpdateFlag() throws {
        let result = try parser.parse(["swift-cpd", "--baseline-update", "Sources/"])

        #expect(result.baselineUpdate == true)
    }

    @Test("Given --baseline with path, when parsing, then captures baseline file path")
    func baselineFilePathFlag() throws {
        let result = try parser.parse(["swift-cpd", "--baseline", "my-baseline.json", "Sources/"])

        #expect(result.baselineFilePath == "my-baseline.json")
    }

    @Test("Given mixed flags and paths, when parsing, then separates them correctly")
    func mixedFlagsAndPaths() throws {
        let result = try parser.parse([
            "swift-cpd", "Sources/", "--min-tokens", "30", "--format", "json", "Tests/",
        ])

        #expect(result.paths == ["Sources/", "Tests/"])
        #expect(result.minimumTokenCount == 30)
        #expect(result.format == .json)
    }

    @Test("Given unknown flag, when parsing, then throws unknownFlag error")
    func unknownFlagThrows() {
        #expect(throws: ArgumentParsingError.unknownFlag("--foo")) {
            try parser.parse(["swift-cpd", "--foo"])
        }
    }

    @Test("Given --min-tokens without value, when parsing, then throws missingValue error")
    func missingValueForMinTokensThrows() {
        #expect(throws: ArgumentParsingError.missingValue("--min-tokens")) {
            try parser.parse(["swift-cpd", "--min-tokens"])
        }
    }

    @Test("Given --min-tokens with non-integer, when parsing, then throws invalidIntegerValue error")
    func invalidIntegerValueThrows() {
        #expect(throws: ArgumentParsingError.invalidIntegerValue("abc", "--min-tokens")) {
            try parser.parse(["swift-cpd", "--min-tokens", "abc"])
        }
    }

    @Test("Given --format with invalid value, when parsing, then throws invalidFormatValue error")
    func invalidFormatValueThrows() {
        #expect(throws: ArgumentParsingError.invalidFormatValue("csv")) {
            try parser.parse(["swift-cpd", "--format", "csv"])
        }
    }

    @Test("Given --config with path, when parsing, then captures config file path")
    func configFlag() throws {
        let result = try parser.parse(["swift-cpd", "--config", "custom.yml", "Sources/"])

        #expect(result.configFilePath == "custom.yml")
    }

    @Test("Given --max-duplication with value, when parsing, then captures threshold")
    func maxDuplicationFlag() throws {
        let result = try parser.parse(["swift-cpd", "--max-duplication", "5.5", "Sources/"])

        #expect(result.maxDuplication == 5.5)
    }

    @Test("Given --max-duplication without value, when parsing, then throws missingValue error")
    func missingValueForMaxDuplicationThrows() {
        #expect(throws: ArgumentParsingError.missingValue("--max-duplication")) {
            try parser.parse(["swift-cpd", "--max-duplication"])
        }
    }

    @Test("Given --max-duplication with non-numeric, when parsing, then throws invalidDuplicationValue error")
    func invalidDuplicationValueThrows() {
        #expect(throws: ArgumentParsingError.invalidDuplicationValue("abc")) {
            try parser.parse(["swift-cpd", "--max-duplication", "abc"])
        }
    }

    @Test("Given --max-duplication with value over 100, when parsing, then throws invalidDuplicationValue error")
    func duplicationValueOverHundredThrows() {
        #expect(throws: ArgumentParsingError.invalidDuplicationValue("101")) {
            try parser.parse(["swift-cpd", "--max-duplication", "101"])
        }
    }

    @Test("Given --max-duplication with negative value, when parsing, then throws invalidDuplicationValue error")
    func negativeDuplicationValueThrows() {
        #expect(throws: ArgumentParsingError.invalidDuplicationValue("-5")) {
            try parser.parse(["swift-cpd", "--max-duplication", "-5"])
        }
    }

    @Test("Given no arguments, when parsing, then returns empty defaults")
    func emptyArgumentsReturnsDefaults() throws {
        let result = try parser.parse(["swift-cpd"])

        #expect(result.paths.isEmpty)
        #expect(result.minimumTokenCount == nil)
        #expect(result.minimumLineCount == nil)
        #expect(result.format == nil)
        #expect(result.showVersion == false)
        #expect(result.showHelp == false)
    }

    @Test("Given --type3-similarity flag, when parsing, then stores value")
    func type3SimilarityFlag() throws {
        let result = try parser.parse(["swift-cpd", "--type3-similarity", "80"])

        #expect(result.type3Similarity == 80)
    }

    @Test("Given --type3-tile-size flag, when parsing, then stores value")
    func type3TileSizeFlag() throws {
        let result = try parser.parse(["swift-cpd", "--type3-tile-size", "3"])

        #expect(result.type3TileSize == 3)
    }

    @Test("Given --type3-candidate-threshold flag, when parsing, then stores value")
    func type3CandidateThresholdFlag() throws {
        let result = try parser.parse(["swift-cpd", "--type3-candidate-threshold", "40"])

        #expect(result.type3CandidateThreshold == 40)
    }

    @Test("Given all Type-3 flags, when parsing, then stores all values")
    func allType3Flags() throws {
        let result = try parser.parse([
            "swift-cpd",
            "--type3-similarity", "75",
            "--type3-tile-size", "4",
            "--type3-candidate-threshold", "25",
        ])

        #expect(result.type3Similarity == 75)
        #expect(result.type3TileSize == 4)
        #expect(result.type3CandidateThreshold == 25)
    }

    @Test("Given --type4-similarity flag, when parsing, then stores value")
    func type4SimilarityFlag() throws {
        let result = try parser.parse(["swift-cpd", "--type4-similarity", "85"])

        #expect(result.type4Similarity == 85)
    }

    @Test("Given --cross-language flag, when parsing, then crossLanguageEnabled is true")
    func crossLanguageFlag() throws {
        let result = try parser.parse(["swift-cpd", "--cross-language", "Sources/"])

        #expect(result.crossLanguageEnabled == true)
    }

    @Test("Given no --cross-language flag, when parsing, then crossLanguageEnabled defaults to false")
    func crossLanguageDefaultFalse() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.crossLanguageEnabled == false)
    }

    @Test("Given --ignore-same-file flag, when parsing, then ignoreSameFile is true")
    func ignoreSameFileFlag() throws {
        let result = try parser.parse(["swift-cpd", "--ignore-same-file", "Sources/"])

        #expect(result.ignoreSameFile == true)
    }

    @Test("Given no --ignore-same-file flag, when parsing, then ignoreSameFile defaults to false")
    func ignoreSameFileDefaultFalse() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.ignoreSameFile == false)
    }

    @Test("Given --ignore-structural flag, when parsing, then ignoreStructural is true")
    func ignoreStructuralFlag() throws {
        let result = try parser.parse(["swift-cpd", "--ignore-structural", "Sources/"])

        #expect(result.ignoreStructural == true)
    }

    @Test("Given no --ignore-structural flag, when parsing, then ignoreStructural defaults to false")
    func ignoreStructuralDefaultFalse() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.ignoreStructural == false)
    }

    @Test("Given --exclude with pattern, when parsing, then captures exclude pattern")
    func excludeFlag() throws {
        let result = try parser.parse(["swift-cpd", "--exclude", "*.generated.swift", "Sources/"])

        #expect(result.excludePatterns == ["*.generated.swift"])
    }

    @Test("Given multiple --exclude flags, when parsing, then accumulates patterns")
    func multipleExcludeFlags() throws {
        let result = try parser.parse([
            "swift-cpd",
            "--exclude", "*.generated.swift",
            "--exclude", "**/Pods/**",
            "Sources/",
        ])

        #expect(result.excludePatterns == ["*.generated.swift", "**/Pods/**"])
    }

    @Test("Given --exclude without value, when parsing, then throws missingValue error")
    func missingValueForExcludeThrows() {
        #expect(throws: ArgumentParsingError.missingValue("--exclude")) {
            try parser.parse(["swift-cpd", "--exclude"])
        }
    }

    @Test("Given --suppression-tag flag, when parsing, then stores value")
    func suppressionTagFlag() throws {
        let result = try parser.parse(["swift-cpd", "--suppression-tag", "nocpd", "Sources/"])

        #expect(result.inlineSuppressionTag == "nocpd")
    }

    @Test("Given no --suppression-tag flag, when parsing, then inlineSuppressionTag is nil")
    func suppressionTagDefaultNil() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.inlineSuppressionTag == nil)
    }

    @Test("Given unknown type3 flag, when parsing, then throws unknownFlag error")
    func unknownType3FlagThrows() {
        #expect(throws: ArgumentParsingError.unknownFlag("--type3-unknown")) {
            try parser.parse(["swift-cpd", "--type3-unknown", "10"])
        }
    }

    @Test("Given unknown type4 flag, when parsing, then throws unknownFlag error")
    func unknownType4FlagThrows() {
        #expect(throws: ArgumentParsingError.unknownFlag("--type4-unknown")) {
            try parser.parse(["swift-cpd", "--type4-unknown", "10"])
        }
    }

    @Test("Given --types with empty string, when parsing, then throws invalidTypesValue error")
    func typesEmptyStringThrows() {
        #expect(throws: ArgumentParsingError.invalidTypesValue("")) {
            try parser.parse(["swift-cpd", "--types", ""])
        }
    }

    @Test("Given --types flag with single type, when parsing, then stores set with one type")
    func typesFlagSingleType() throws {
        let result = try parser.parse(["swift-cpd", "--types", "1", "Sources/"])

        #expect(result.enabledCloneTypes == [.type1])
    }

    @Test("Given --types flag with multiple types, when parsing, then stores set with all specified types")
    func typesFlagMultipleTypes() throws {
        let result = try parser.parse(["swift-cpd", "--types", "1,3", "Sources/"])

        #expect(result.enabledCloneTypes == [.type1, .type3])
    }

    @Test("Given --types flag with all types, when parsing, then stores complete set")
    func typesFlagAllTypes() throws {
        let result = try parser.parse(["swift-cpd", "--types", "1,2,3,4", "Sources/"])

        #expect(result.enabledCloneTypes == Set(CloneType.allCases))
    }

    @Test("Given --types flag with invalid value, when parsing, then throws invalidTypesValue error")
    func typesFlagInvalidValue() {
        #expect(throws: ArgumentParsingError.invalidTypesValue("5")) {
            try parser.parse(["swift-cpd", "--types", "5"])
        }
    }

    @Test("Given --types flag with non-numeric value, when parsing, then throws invalidTypesValue error")
    func typesFlagNonNumericValue() {
        #expect(throws: ArgumentParsingError.invalidTypesValue("abc")) {
            try parser.parse(["swift-cpd", "--types", "abc"])
        }
    }

    @Test("Given no --types flag, when parsing, then enabledCloneTypes is nil")
    func typesDefaultNil() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.enabledCloneTypes == nil)
    }

    @Test("Given --types all, when parsing, then returns all clone types")
    func typesAllValue() throws {
        let result = try parser.parse(["swift-cpd", "--types", "all", "Sources/"])

        #expect(result.enabledCloneTypes == Set(CloneType.allCases))
    }

    @Test("Given init command, when parsing, then showInit is true")
    func initCommand() throws {
        let result = try parser.parse(["swift-cpd", "init"])

        #expect(result.showInit == true)
        #expect(result.paths.isEmpty)
    }

    @Test("Given init with flags, when parsing, then showInit is true and flags are parsed")
    func initWithFlags() throws {
        let result = try parser.parse(["swift-cpd", "init", "--format", "json"])

        #expect(result.showInit == true)
        #expect(result.format == .json)
    }

    @Test("Given --cache-dir with path, when parsing, then captures cache directory")
    func cacheDirFlag() throws {
        let result = try parser.parse(["swift-cpd", "--cache-dir", "/tmp/cache", "Sources/"])

        #expect(result.cacheDirectory == "/tmp/cache")
    }

    @Test("Given no --cache-dir flag, when parsing, then cacheDirectory is nil")
    func cacheDirDefaultNil() throws {
        let result = try parser.parse(["swift-cpd", "Sources/"])

        #expect(result.cacheDirectory == nil)
    }

    @Test("Given --cache-dir without value, when parsing, then throws missingValue error")
    func missingValueForCacheDirThrows() {
        #expect(throws: ArgumentParsingError.missingValue("--cache-dir")) {
            try parser.parse(["swift-cpd", "--cache-dir"])
        }
    }
}
