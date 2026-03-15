import Testing

@testable import swift_cpd

@Suite("Configuration Type-4")
struct ConfigurationType4Tests {

    @Test("Given YAML type4Similarity without CLI, when creating configuration, then uses YAML value")
    func yamlType4SimilarityFallback() throws {
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
            type4Similarity: 85,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.type4Similarity == 85)
    }

    @Test("Given CLI and YAML type4Similarity, when creating configuration, then CLI value wins")
    func cliOverridesYamlType4Similarity() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.type4Similarity = 90
        let yaml = YamlConfiguration(
            minimumTokenCount: nil,
            minimumLineCount: nil,
            outputFormat: nil,
            paths: nil,
            maxDuplication: nil,
            type3Similarity: nil,
            type3TileSize: nil,
            type3CandidateThreshold: nil,
            type4Similarity: 85,
            crossLanguageEnabled: nil,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.type4Similarity == 90)
    }

    @Test("Given no Type-4 values in CLI or YAML, when creating configuration, then uses built-in default")
    func type4BuiltInDefault() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.type4Similarity == 80)
    }
}
