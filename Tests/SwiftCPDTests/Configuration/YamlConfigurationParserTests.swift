import Testing

@testable import swift_cpd

@Suite("YamlConfigurationParser")
struct YamlConfigurationParserTests {

    let parser = YamlConfigurationParser()

    @Test("Given integer scalar, when parsing, then decodes correctly")
    func intScalar() throws {
        let config = try parser.parse("minimumTokenCount: 42")

        #expect(config.minimumTokenCount == 42)
    }

    @Test("Given double scalar, when parsing, then decodes correctly")
    func doubleScalar() throws {
        let config = try parser.parse("maxDuplication: 3.14")

        #expect(config.maxDuplication == 3.14)
    }

    @Test("Given bool true scalar, when parsing, then decodes correctly")
    func boolTrue() throws {
        let config = try parser.parse("ignoreSameFile: true")

        #expect(config.ignoreSameFile == true)
    }

    @Test("Given bool false scalar, when parsing, then decodes correctly")
    func boolFalse() throws {
        let config = try parser.parse("ignoreSameFile: false")

        #expect(config.ignoreSameFile == false)
    }

    @Test("Given bool yes/no, when parsing, then decodes correctly")
    func boolYesNo() throws {
        let withYes = try parser.parse("crossLanguageEnabled: yes")
        let withNo = try parser.parse("crossLanguageEnabled: no")

        #expect(withYes.crossLanguageEnabled == true)
        #expect(withNo.crossLanguageEnabled == false)
    }

    @Test("Given string scalar, when parsing, then decodes correctly")
    func stringScalar() throws {
        let config = try parser.parse("outputFormat: json")

        #expect(config.outputFormat == "json")
    }

    @Test("Given double-quoted string, when parsing, then strips quotes")
    func doubleQuotedString() throws {
        let config = try parser.parse(#"outputFormat: "json""#)

        #expect(config.outputFormat == "json")
    }

    @Test("Given single-quoted string, when parsing, then strips quotes")
    func singleQuotedString() throws {
        let config = try parser.parse("outputFormat: 'json'")

        #expect(config.outputFormat == "json")
    }

    @Test("Given block array, when parsing, then decodes all items")
    func blockArray() throws {
        let config = try parser.parse(
            """
            paths:
              - Sources/
              - Tests/
            """
        )

        #expect(config.paths == ["Sources/", "Tests/"])
    }

    @Test("Given integer block array, when parsing, then decodes all items")
    func intBlockArray() throws {
        let config = try parser.parse(
            """
            enabledCloneTypes:
              - 1
              - 2
              - 3
            """
        )

        #expect(config.enabledCloneTypes == [1, 2, 3])
    }

    @Test("Given inline empty array, when parsing, then returns empty array")
    func inlineEmptyArray() throws {
        let config = try parser.parse("exclude: []")

        #expect(config.exclude == [])
    }

    @Test("Given comment line, when parsing, then ignores it")
    func commentLine() throws {
        let config = try parser.parse(
            """
            # this is a comment
            minimumTokenCount: 10
            """
        )

        #expect(config.minimumTokenCount == 10)
    }

    @Test("Given inline comment, when parsing, then strips it")
    func inlineComment() throws {
        let config = try parser.parse("outputFormat: text # preferred format")

        #expect(config.outputFormat == "text")
    }

    @Test("Given unknown keys, when parsing, then ignores them")
    func unknownKeysIgnored() throws {
        let config = try parser.parse(
            """
            minimumTokenCount: 20
            unknownFeature: true
            futureThreshold: 99
            """
        )

        #expect(config.minimumTokenCount == 20)
    }

    @Test("Given missing keys, when parsing, then fields are nil")
    func missingKeysAreNil() throws {
        let config = try parser.parse("minimumTokenCount: 5")

        #expect(config.minimumLineCount == nil)
        #expect(config.outputFormat == nil)
        #expect(config.paths == nil)
        #expect(config.maxDuplication == nil)
    }

    @Test("Given orphaned array item with no preceding key, when parsing, then throws")
    func orphanedArrayItemThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("- orphan")
        }
    }

    @Test("Given line without colon separator, when parsing, then throws")
    func lineWithoutColonThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("invalidline")
        }
    }

    @Test("Given invalid flow sequence, when parsing, then throws")
    func invalidFlowSequenceThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("minimumTokenCount: [invalid")
        }
    }

    @Test("Given non-integer value for int field, when parsing, then throws")
    func invalidIntValueThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("minimumTokenCount: notanumber")
        }
    }

    @Test("Given non-double value for double field, when parsing, then throws")
    func invalidDoubleValueThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("maxDuplication: notanumber")
        }
    }

    @Test("Given non-bool value for bool field, when parsing, then throws")
    func invalidBoolValueThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse("ignoreSameFile: maybe")
        }
    }

    @Test("Given non-integer item in integer array, when parsing, then throws")
    func invalidIntInArrayThrows() {
        #expect(throws: (any Error).self) {
            try parser.parse(
                """
                enabledCloneTypes:
                  - 1
                  - abc
                """
            )
        }
    }

    @Test("Given empty content, when parsing, then returns all-nil config")
    func emptyContentReturnsAllNil() throws {
        let config = try parser.parse("")

        #expect(config.minimumTokenCount == nil)
        #expect(config.minimumLineCount == nil)
        #expect(config.outputFormat == nil)
        #expect(config.paths == nil)
    }

    @Test("Given full config, when parsing, then decodes all fields")
    func fullConfig() throws {
        let config = try parser.parse(
            """
            minimumTokenCount: 50
            minimumLineCount: 5
            outputFormat: text
            maxDuplication: 10.0
            type3Similarity: 70
            type3TileSize: 4
            type3CandidateThreshold: 3
            type4Similarity: 80
            crossLanguageEnabled: false
            inlineSuppressionTag: swiftcpd:ignore
            ignoreSameFile: true
            ignoreStructural: true
            paths:
              - Sources/
            exclude: []
            enabledCloneTypes:
              - 1
              - 2
            """
        )

        #expect(config.minimumTokenCount == 50)
        #expect(config.minimumLineCount == 5)
        #expect(config.outputFormat == "text")
        #expect(config.maxDuplication == 10.0)
        #expect(config.type3Similarity == 70)
        #expect(config.type3TileSize == 4)
        #expect(config.type3CandidateThreshold == 3)
        #expect(config.type4Similarity == 80)
        #expect(config.crossLanguageEnabled == false)
        #expect(config.inlineSuppressionTag == "swiftcpd:ignore")
        #expect(config.ignoreSameFile == true)
        #expect(config.ignoreStructural == true)
        #expect(config.paths == ["Sources/"])
        #expect(config.exclude == [])
        #expect(config.enabledCloneTypes == [1, 2])
    }
}
