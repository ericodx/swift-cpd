import Testing

@testable import swift_cpd

@Suite("Configuration")
struct ConfigurationTests {

    @Test("Given parsed arguments with paths only, when creating configuration, then uses default values")
    func defaultValues() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let config = try Configuration(from: parsed)

        #expect(config.minimumTokenCount == 50)
        #expect(config.minimumLineCount == 5)
        #expect(config.outputFormat == .text)
        #expect(config.outputFilePath == nil)
        #expect(config.baselineMode == .none)
        #expect(config.baselineFilePath == ".swiftcpd-baseline.json")
    }

    @Test("Given custom min-tokens, when creating configuration, then overrides default")
    func customMinTokens() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 30

        let config = try Configuration(from: parsed)

        #expect(config.minimumTokenCount == 30)
    }

    @Test("Given custom min-lines, when creating configuration, then overrides default")
    func customMinLines() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumLineCount = 3

        let config = try Configuration(from: parsed)

        #expect(config.minimumLineCount == 3)
    }

    @Test("Given custom format, when creating configuration, then overrides default")
    func customFormat() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.format = .json

        let config = try Configuration(from: parsed)

        #expect(config.outputFormat == .json)
    }

    @Test("Given no paths, when creating configuration, then throws noPathsSpecified error")
    func missingPathsThrows() {
        let parsed = ParsedArguments()

        #expect(throws: ConfigurationError.noPathsSpecified) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given baseline-generate flag, when creating configuration, then mode is generate")
    func baselineGenerateMode() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.baselineGenerate = true

        let config = try Configuration(from: parsed)

        #expect(config.baselineMode == .generate)
    }

    @Test("Given baseline-update flag, when creating configuration, then mode is update")
    func baselineUpdateMode() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.baselineUpdate = true

        let config = try Configuration(from: parsed)

        #expect(config.baselineMode == .update)
    }

    @Test("Given baseline file path without flags, when creating configuration, then mode is compare")
    func baselineCompareMode() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.baselineFilePath = "my-baseline.json"

        let config = try Configuration(from: parsed)

        #expect(config.baselineMode == .compare)
        #expect(config.baselineFilePath == "my-baseline.json")
    }

    @Test("Given YAML paths without CLI paths, when creating configuration, then uses YAML paths")
    func yamlPathsFallback() throws {
        let parsed = ParsedArguments()
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: ["Lib/"],
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.paths == ["Lib/"])
    }

    @Test("Given CLI and YAML paths, when creating configuration, then CLI paths win")
    func cliOverridesYamlPaths() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: ["Lib/"],
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.paths == ["Sources/"])
    }

    @Test("Given YAML minTokens without CLI, when creating configuration, then uses YAML value")
    func yamlMinTokensFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: 30,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.minimumTokenCount == 30)
    }

    @Test("Given CLI and YAML minTokens, when creating configuration, then CLI value wins")
    func cliOverridesYamlMinTokens() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 40
        let yaml = YamlConfiguration(
            minimumTokenCount: 30,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.minimumTokenCount == 40)
    }

    @Test("Given YAML format without CLI, when creating configuration, then uses YAML format")
    func yamlFormatFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: "json",
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.outputFormat == .json)
    }

    @Test("Given no CLI or YAML values, when creating configuration, then uses built-in defaults")
    func builtInDefaults() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.minimumTokenCount == 50)
        #expect(config.minimumLineCount == 5)
        #expect(config.outputFormat == .text)
        #expect(config.maxDuplication == nil)
    }

    @Test("Given YAML maxDuplication without CLI, when creating configuration, then uses YAML value")
    func yamlMaxDuplicationFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: 10.5,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.maxDuplication == 10.5)
    }

    @Test("Given CLI and YAML maxDuplication, when creating configuration, then CLI value wins")
    func cliOverridesYamlMaxDuplication() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.maxDuplication = 5.0
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: 10.5,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.maxDuplication == 5.0)
    }

    @Test("Given no maxDuplication in CLI or YAML, when creating configuration, then maxDuplication is nil")
    func nilMaxDuplication() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.maxDuplication == nil)
    }

    @Test("Given minimumTokenCount below range, when creating configuration, then throws parameterOutOfRange")
    func minimumTokenCountBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 9

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "minimumTokenCount",
                value: 9,
                validRange: 10 ... 500
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given minimumTokenCount above range, when creating configuration, then throws parameterOutOfRange")
    func minimumTokenCountAboveRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 501

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "minimumTokenCount",
                value: 501,
                validRange: 10 ... 500
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given minimumLineCount below range, when creating configuration, then throws parameterOutOfRange")
    func minimumLineCountBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumLineCount = 1

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "minimumLineCount",
                value: 1,
                validRange: 2 ... 100
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given type3Similarity below range, when creating configuration, then throws parameterOutOfRange")
    func type3SimilarityBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type3Similarity = 49

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "type3Similarity",
                value: 49,
                validRange: 50 ... 100
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given type3TileSize below range, when creating configuration, then throws parameterOutOfRange")
    func type3TileSizeBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type3TileSize = 1

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "type3TileSize",
                value: 1,
                validRange: 2 ... 20
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given type3CandidateThreshold below range, when creating configuration, then throws parameterOutOfRange")
    func type3CandidateThresholdBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type3CandidateThreshold = 9

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "type3CandidateThreshold",
                value: 9,
                validRange: 10 ... 80
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given type4Similarity below range, when creating configuration, then throws parameterOutOfRange")
    func type4SimilarityBelowRange() {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type4Similarity = 59

        #expect(
            throws: ConfigurationError.parameterOutOfRange(
                name: "type4Similarity",
                value: 59,
                validRange: 60 ... 100
            )
        ) {
            try Configuration(from: parsed)
        }
    }

    @Test("Given parameters at boundary values, when creating configuration, then accepts them")
    func boundaryValuesAccepted() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 10
        parsed.minimumLineCount = 2
        parsed.type3Similarity = 50
        parsed.type3TileSize = 2
        parsed.type3CandidateThreshold = 10
        parsed.type4Similarity = 60

        let config = try Configuration(from: parsed)

        #expect(config.minimumTokenCount == 10)
        #expect(config.minimumLineCount == 2)
        #expect(config.type3Similarity == 50)
        #expect(config.type3TileSize == 2)
        #expect(config.type3CandidateThreshold == 10)
        #expect(config.type4Similarity == 60)
    }

    @Test("Given parameters at upper boundary values, when creating configuration, then accepts them")
    func upperBoundaryValuesAccepted() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.minimumTokenCount = 500
        parsed.minimumLineCount = 100
        parsed.type3Similarity = 100
        parsed.type3TileSize = 20
        parsed.type3CandidateThreshold = 80
        parsed.type4Similarity = 100

        let config = try Configuration(from: parsed)

        #expect(config.minimumTokenCount == 500)
        #expect(config.minimumLineCount == 100)
        #expect(config.type3Similarity == 100)
        #expect(config.type3TileSize == 20)
        #expect(config.type3CandidateThreshold == 80)
        #expect(config.type4Similarity == 100)
    }

    @Test("Given no suppression tag, when creating configuration, then uses default tag")
    func defaultSuppressionTag() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.inlineSuppressionTag == "swiftcpd:ignore")
    }

    @Test("Given CLI suppression tag, when creating configuration, then uses CLI value")
    func cliSuppressionTag() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.inlineSuppressionTag = "nocpd"

        let config = try Configuration(from: parsed)

        #expect(config.inlineSuppressionTag == "nocpd")
    }

    @Test("Given YAML suppression tag without CLI, when creating configuration, then uses YAML value")
    func yamlSuppressionTagFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: "custom:skip",
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.inlineSuppressionTag == "custom:skip")
    }

    @Test("Given CLI and YAML suppression tag, when creating configuration, then CLI value wins")
    func cliOverridesYamlSuppressionTag() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.inlineSuppressionTag = "nocpd"
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: "custom:skip",
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.inlineSuppressionTag == "nocpd")
    }

    @Test("Given no enabled clone types, when creating configuration, then defaults to all types")
    func defaultEnabledCloneTypes() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.enabledCloneTypes == Set(CloneType.allCases))
    }

    @Test("Given CLI enabled clone types, when creating configuration, then uses CLI value")
    func cliEnabledCloneTypes() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.enabledCloneTypes = [.type1, .type3]

        let config = try Configuration(from: parsed)

        #expect(config.enabledCloneTypes == [.type1, .type3])
    }

    @Test("Given no cache directory, when creating configuration, then uses default")
    func defaultCacheDirectory() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.cacheDirectory == ".swiftcpd-cache")
    }

    @Test("Given CLI cache directory, when creating configuration, then uses CLI value")
    func cliCacheDirectory() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.cacheDirectory = "/tmp/derived-data/cache"

        let config = try Configuration(from: parsed)

        #expect(config.cacheDirectory == "/tmp/derived-data/cache")
    }

}
