import Foundation
import Testing

@testable import swift_cpd

@Suite("YamlConfigurationLoader")
struct YamlConfigurationLoaderTests {

    let loader = YamlConfigurationLoader()

    @Test(
        "Given valid YAML with all fields, when loading, then decodes all values"
    )
    func allFields() throws {
        let tempFile = createTempFile(
            content: """
                minimumTokenCount: 30
                minimumLineCount: 3
                outputFormat: json
                maxDuplication: 5.5
                paths:
                  - Sources/
                  - Tests/
                """,
            prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        let config = try loader.load(from: tempFile)

        #expect(config.minimumTokenCount == 30)
        #expect(config.minimumLineCount == 3)
        #expect(config.outputFormat == "json")
        #expect(config.maxDuplication == 5.5)
        #expect(config.paths == ["Sources/", "Tests/"])
    }

    @Test(
        "Given valid YAML with partial fields, when loading, then missing fields are nil"
    )
    func partialFields() throws {
        let tempFile = createTempFile(
            content: """
                minimumTokenCount: 40
                """,
            prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        let config = try loader.load(from: tempFile)

        #expect(config.minimumTokenCount == 40)
        #expect(config.minimumLineCount == nil)
        #expect(config.outputFormat == nil)
        #expect(config.maxDuplication == nil)
        #expect(config.paths == nil)
    }

    @Test(
        "Given empty YAML file, when loading, then returns config with all nil fields"
    )
    func emptyFile() throws {
        let tempFile = createTempFile(content: "", prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        let config = try loader.load(from: tempFile)

        #expect(config.minimumTokenCount == nil)
        #expect(config.minimumLineCount == nil)
        #expect(config.outputFormat == nil)
        #expect(config.maxDuplication == nil)
        #expect(config.paths == nil)
    }

    @Test(
        "Given non-existent file, when loading, then throws fileNotReadable"
    )
    func missingFileThrows() {
        #expect(
            throws:
                YamlConfigurationError
                .fileNotReadable("/nonexistent/config.yml")
        ) {
            try loader.load(from: "/nonexistent/config.yml")
        }
    }

    @Test(
        "Given invalid YAML syntax, when loading, then throws invalidYaml"
    )
    func invalidYamlThrows() throws {
        let tempFile = createTempFile(
            content: """
                minimumTokenCount: [invalid
                """,
            prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        #expect(
            throws:
                YamlConfigurationError
                .invalidYaml(tempFile)
        ) {
            try loader.load(from: tempFile)
        }
    }

    @Test(
        "Given non-existent file, when loadIfExists, then returns nil"
    )
    func loadIfExistsMissingReturnsNil() throws {
        let result = try loader.loadIfExists(from: "/nonexistent/config.yml")

        #expect(result == nil)
    }

    @Test(
        "Given existing valid file, when loadIfExists, then returns decoded config"
    )
    func loadIfExistsReturnsConfig() throws {
        let tempFile = createTempFile(
            content: """
                minimumTokenCount: 25
                """,
            prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        let config = try loader.loadIfExists(from: tempFile)

        #expect(config?.minimumTokenCount == 25)
    }

    @Test(
        "Given YAML with unknown keys, when loading, then ignores unknown keys"
    )
    func unknownKeysIgnored() throws {
        let tempFile = createTempFile(
            content: """
                minimumTokenCount: 50
                unknownFeature: true
                futureThreshold: 99
                """,
            prefix: "YamlConfigTest")
        defer { removeTempFile(tempFile) }

        let config = try loader.load(from: tempFile)

        #expect(config.minimumTokenCount == 50)
    }
}
