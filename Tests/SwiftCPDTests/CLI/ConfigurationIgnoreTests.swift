import Testing

@testable import swift_cpd

@Suite("Configuration Ignore Flags")
struct ConfigurationIgnoreTests {

    @Test("Given YAML ignoreSameFile true, when creating configuration, then uses YAML value")
    func yamlIgnoreSameFile() throws {
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
            ignoreSameFile: true,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.ignoreSameFile == true)
    }

    @Test("Given CLI --ignore-same-file overrides YAML false, when creating configuration, then CLI wins")
    func cliIgnoreSameFileOverridesYaml() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.ignoreSameFile = true
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
            ignoreSameFile: false,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.ignoreSameFile == true)
    }

    @Test("Given YAML ignoreStructural true, when creating configuration, then uses YAML value")
    func yamlIgnoreStructural() throws {
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
            ignoreStructural: true
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.ignoreStructural == true)
    }

    @Test("Given CLI --ignore-structural overrides YAML false, when creating configuration, then CLI wins")
    func cliIgnoreStructuralOverridesYaml() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.ignoreStructural = true
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
            ignoreStructural: false
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.ignoreStructural == true)
    }

    @Test("Given YAML enabled clone types without CLI, when creating configuration, then uses YAML value")
    func yamlEnabledCloneTypesFallback() throws {
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
            enabledCloneTypes: [1, 2],
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.enabledCloneTypes == [.type1, .type2])
    }

    @Test("Given CLI and YAML enabled clone types, when creating configuration, then CLI value wins")
    func cliOverridesYamlEnabledCloneTypes() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.enabledCloneTypes = [.type4]
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
            enabledCloneTypes: [1, 2],
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.enabledCloneTypes == [.type4])
    }
}
