import Testing

@testable import swift_cpd

@Suite("Configuration Cross-Language")
struct ConfigurationCrossLanguageTests {

    @Test("Given no cross-language flags, when creating configuration, then defaults to false")
    func crossLanguageDefaultsFalse() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.crossLanguageEnabled == false)
    }

    @Test("Given YAML crossLanguageEnabled true, when creating configuration, then uses YAML value")
    func yamlCrossLanguageFallback() throws {
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
            crossLanguageEnabled: true,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.crossLanguageEnabled == true)
    }

    @Test("Given parsed crossLanguageEnabled true, when creating configuration, then uses parsed value")
    func parsedCrossLanguageEnabled() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.crossLanguageEnabled = true

        let config = try Configuration(from: parsed)

        #expect(config.crossLanguageEnabled == true)
    }

    @Test("Given parsed and YAML crossLanguageEnabled, when creating configuration, then parsed wins")
    func parsedOverridesYaml() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.crossLanguageEnabled = true
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
            crossLanguageEnabled: false,
            exclude: nil,
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.crossLanguageEnabled == true)
    }
}
