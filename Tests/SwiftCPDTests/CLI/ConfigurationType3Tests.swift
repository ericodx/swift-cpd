import Testing

@testable import swift_cpd

@Suite("Configuration Type-3")
struct ConfigurationType3Tests {

    @Test("Given YAML type3Similarity without CLI, when creating configuration, then uses YAML value")
    func yamlType3SimilarityFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: 80,
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

        #expect(config.type3Similarity == 80)
    }

    @Test("Given CLI and YAML type3Similarity, when creating configuration, then CLI value wins")
    func cliOverridesYamlType3Similarity() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type3Similarity = 90
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: 80,
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

        #expect(config.type3Similarity == 90)
    }

    @Test("Given YAML type3TileSize without CLI, when creating configuration, then uses YAML value")
    func yamlType3TileSizeFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: 3,
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

        #expect(config.type3TileSize == 3)
    }

    @Test("Given YAML type3CandidateThreshold without CLI, when creating configuration, then uses YAML value")
    func yamlType3CandidateThresholdFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: 40,
            type4Similarity: nil,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.type3CandidateThreshold == 40)
    }

    @Test("Given no Type-3 values in CLI or YAML, when creating configuration, then uses built-in defaults")
    func type3BuiltInDefaults() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.type3Similarity == 70)
        #expect(config.type3TileSize == 5)
        #expect(config.type3CandidateThreshold == 30)
    }
}
