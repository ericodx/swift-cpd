import Testing

@testable import swift_cpd

@Suite("Configuration Exclude")
struct ConfigurationExcludeTests {

    @Test("Given no exclude patterns, when creating configuration, then excludePatterns is empty")
    func defaultExcludeIsEmpty() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.excludePatterns.isEmpty)
    }

    @Test("Given CLI exclude patterns, when creating configuration, then uses CLI patterns")
    func cliExcludePatterns() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.excludePatterns = ["*.generated.swift", "**/Pods/**"]

        let config = try Configuration(from: parsed)

        #expect(config.excludePatterns == ["*.generated.swift", "**/Pods/**"])
    }

    @Test("Given YAML exclude patterns, when creating configuration, then uses YAML patterns")
    func yamlExcludePatterns() throws {
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
            exclude: ["**/Generated/**"],
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.excludePatterns == ["**/Generated/**"])
    }

    @Test("Given CLI and YAML exclude patterns, when creating configuration, then merges both")
    func mergesCLIAndYamlPatterns() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.excludePatterns = ["*.generated.swift"]
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
            exclude: ["**/Generated/**"],
            inlineSuppressionTag: nil,
            enabledCloneTypes: nil,
            ignoreSameFile: nil,
            ignoreStructural: nil
        )

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.excludePatterns == ["*.generated.swift", "**/Generated/**"])
    }
}
