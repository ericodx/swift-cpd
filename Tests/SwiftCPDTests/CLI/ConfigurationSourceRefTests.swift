import Testing

@testable import swift_cpd

@Suite("Configuration sourceRef")
struct ConfigurationSourceRefTests {

    @Test("Given sourceRef in both CLI and YAML, when creating configuration, then CLI wins (C1)")
    func cliOverridesYaml() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.sourceRef = "HEAD"
        let yaml = makeYaml(sourceRef: "main")

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.sourceRef == "HEAD")
    }

    @Test("Given sourceRef only in YAML, when creating configuration, then uses YAML (C2)")
    func yamlFallback() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = makeYaml(sourceRef: "HEAD")

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.sourceRef == "HEAD")
    }

    @Test("Given no sourceRef in CLI or YAML, when creating configuration, then sourceRef is nil (C3)")
    func absentIsNil() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])

        let config = try Configuration(from: parsed)

        #expect(config.sourceRef == nil)
    }

    @Test("Given empty CLI sourceRef, when creating configuration, then treated as nil (C4)")
    func emptyCliTreatedAsNil() throws {
        var parsed = ParsedArguments(paths: ["Sources/"])
        parsed.sourceRef = ""

        let config = try Configuration(from: parsed)

        #expect(config.sourceRef == nil)
    }

    @Test("Given empty YAML sourceRef, when creating configuration, then treated as nil")
    func emptyYamlTreatedAsNil() throws {
        let parsed = ParsedArguments(paths: ["Sources/"])
        let yaml = makeYaml(sourceRef: "")

        let config = try Configuration(from: parsed, yaml: yaml)

        #expect(config.sourceRef == nil)
    }

    private func makeYaml(sourceRef: String) -> YamlConfiguration {
        YamlConfiguration(
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
            ignoreStructural: nil,
            noCache: nil,
            sourceRef: sourceRef
        )
    }
}
