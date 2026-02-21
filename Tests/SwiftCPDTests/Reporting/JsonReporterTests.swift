import Foundation
import Testing

@testable import swift_cpd

@Suite("JsonReporter")
struct JsonReporterTests {

    let reporter = JsonReporter()

    @Test("Given no clones, when reporting, then produces valid JSON with empty clones array")
    func emptyClonesProducesValidJson() throws {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 10,
            executionTime: 0.5,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        let clones = try #require(json["clones"] as? [Any])
        #expect(clones.isEmpty)
    }

    @Test("Given clones, when reporting, then produces valid JSON matching expected schema")
    func validJsonSchema() throws {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 52,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 10, endLine: 17, startColumn: 1, endColumn: 2),
                CloneFragment(file: "B.swift", startLine: 22, endLine: 29, startColumn: 1, endColumn: 2),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 5,
            executionTime: 0.85,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["version"] as? String == "1.0.0")

        let metadata = try #require(json["metadata"] as? [String: Any])
        #expect(metadata["filesAnalyzed"] as? Int == 5)

        let clones = try #require(json["clones"] as? [[String: Any]])
        #expect(clones.count == 1)
        #expect(clones[0]["type"] as? Int == 1)
        #expect(clones[0]["tokenCount"] as? Int == 52)
    }

    @Test("Given multiple clones, when reporting, then summary counts are correct")
    func summaryCountsAreCorrect() throws {
        let clone1 = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)
            ]
        )
        let clone2 = CloneGroup(
            type: .type2,
            tokenCount: 30,
            lineCount: 5,
            similarity: 85.0,
            fragments: [
                CloneFragment(file: "B.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone1, clone2],
            filesAnalyzed: 2,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let summary = try #require(json["summary"] as? [String: Any])

        #expect(summary["totalClones"] as? Int == 2)
        #expect(summary["duplicatedTokens"] as? Int == 80)
        #expect(summary["duplicatedLines"] as? Int == 13)
    }

    @Test("Given multiple clones, when reporting, then clone IDs are sequential")
    func sequentialCloneIds() throws {
        let clone1 = CloneGroup(
            type: .type1, tokenCount: 50, lineCount: 8, similarity: 100.0,
            fragments: [CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)]
        )
        let clone2 = CloneGroup(
            type: .type1, tokenCount: 30, lineCount: 5, similarity: 100.0,
            fragments: [CloneFragment(file: "B.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2)]
        )
        let result = AnalysisResult(
            cloneGroups: [clone1, clone2],
            filesAnalyzed: 2,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let clones = try #require(json["clones"] as? [[String: Any]])

        #expect(clones[0]["id"] as? String == "clone-001")
        #expect(clones[1]["id"] as? String == "clone-002")
    }

    @Test("Given analysis result, when reporting, then metadata contains configuration and totalTokens")
    func metadataContainsConfigurationAndTotalTokens() throws {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 10,
            executionTime: 0.5,
            totalTokens: 5000,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let metadata = try #require(json["metadata"] as? [String: Any])

        #expect(metadata["totalTokens"] as? Int == 5000)

        let configuration = try #require(metadata["configuration"] as? [String: Any])
        #expect(configuration["minimumTokenCount"] as? Int == 50)
        #expect(configuration["minimumLineCount"] as? Int == 5)
    }

    @Test("Given fragment with real file, when reporting, then JSON contains preview field")
    func fragmentContainsPreview() throws {
        let tempDir = NSTemporaryDirectory() + "JsonReporterTests-" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let filePath = tempDir + "/Sample.swift"
        let source = "func hello() {\n    print(\"hello\")\n}\n"
        try source.write(toFile: filePath, atomically: true, encoding: .utf8)

        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 3,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: filePath, startLine: 1, endLine: 3, startColumn: 1, endColumn: 2),
                CloneFragment(file: filePath, startLine: 1, endLine: 3, startColumn: 1, endColumn: 2),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let clones = try #require(json["clones"] as? [[String: Any]])
        let fragments = try #require(clones[0]["fragments"] as? [[String: Any]])

        #expect(fragments[0]["preview"] as? String == "func hello() { ... }")
    }

    @Test("Given fragment with nonexistent file, when reporting, then preview is empty")
    func nonexistentFilePreviewIsEmpty() throws {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "/nonexistent/File.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let clones = try #require(json["clones"] as? [[String: Any]])
        let fragments = try #require(clones[0]["fragments"] as? [[String: Any]])

        #expect(fragments[0]["preview"] as? String == "")
    }

    @Test("Given fragment spanning single line, when reporting, then preview is just the line without ellipsis")
    func singleLinePreview() throws {
        let tempDir = NSTemporaryDirectory() + "JsonReporterSingleLine-" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let filePath = tempDir + "/One.swift"
        let source = "let x = 42\nlet y = 99\n"
        try source.write(toFile: filePath, atomically: true, encoding: .utf8)

        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 1,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: filePath, startLine: 1, endLine: 1, startColumn: 1, endColumn: 11),
                CloneFragment(file: filePath, startLine: 2, endLine: 2, startColumn: 1, endColumn: 11),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 50,
            minimumLineCount: 1
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let clones = try #require(json["clones"] as? [[String: Any]])
        let fragments = try #require(clones[0]["fragments"] as? [[String: Any]])

        #expect(fragments[0]["preview"] as? String == "let x = 42")
    }

    @Test("Given unencodable result, when reporting, then returns empty JSON object")
    func unencodableResultReturnsEmptyJson() {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: .nan,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        #expect(output == "{}")
    }

    @Test("Given clones, when reporting, then summary contains duplicationPercentage")
    func summaryContainsDuplicationPercentage() throws {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 100,
            lineCount: 10,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
                CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 2,
            executionTime: 0.1,
            totalTokens: 1000,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let summary = try #require(json["summary"] as? [String: Any])

        #expect(summary["duplicationPercentage"] as? Double == 10.0)
    }
}
