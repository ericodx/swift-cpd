import Foundation
import Testing

@testable import swift_cpd

@Suite("EndToEndAnalysis")
struct EndToEndAnalysisTests {

    @Test(
        "Given directory with duplicates, when running full pipeline with text format, then report contains clone info")
    func textFormatWithDuplicates() async throws {
        let tempDir = createTempDirectory(prefix: "EndToEndAnalysis")
        defer { removeTempDirectory(tempDir) }

        let source = standardDuplicateSource
        try source.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try source.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "text")
        let output = TextReporter().report(result)

        #expect(output.contains("clone"))
        #expect(output.contains("2 files"))
        #expect(!result.cloneGroups.isEmpty)
    }

    @Test(
        "Given duplicates, when running full pipeline with json format, then output is valid JSON with clones"
    )
    func jsonFormatWithDuplicates() async throws {
        let tempDir = createTempDirectory(prefix: "EndToEndAnalysis")
        defer { removeTempDirectory(tempDir) }

        let source = standardDuplicateSource
        try source.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try source.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "json")
        let output = JsonReporter().report(result)
        let data = try #require(output.data(using: .utf8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["version"] as? String == "1.0.0")

        let clones = try #require(json["clones"] as? [[String: Any]])
        #expect(!clones.isEmpty)

        let summary = try #require(json["summary"] as? [String: Any])
        #expect(summary["totalClones"] as? Int ?? 0 > 0)
    }

    @Test(
        "Given duplicates, when running full pipeline with xcode format, then output has Xcode warning format"
    )
    func xcodeFormatWithDuplicates() async throws {
        let tempDir = createTempDirectory(prefix: "EndToEndAnalysis")
        defer { removeTempDirectory(tempDir) }

        let source = standardDuplicateSource
        try source.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try source.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "xcode")
        let output = XcodeReporter().report(result)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(!lines.isEmpty)
        #expect(lines.allSatisfy { $0.contains(": warning:") })
        #expect(lines.allSatisfy { $0.contains("\u{2014} also in") })
    }

    @Test(
        "Given duplicates, when running full pipeline with html format, then output contains HTML clone elements"
    )
    func htmlFormatWithDuplicates() async throws {
        let tempDir = createTempDirectory(prefix: "EndToEndAnalysis")
        defer { removeTempDirectory(tempDir) }

        let source = standardDuplicateSource
        try source.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try source.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "html")
        let output = HtmlReporter().report(result)

        #expect(output.contains("<!DOCTYPE html>"))
        #expect(output.contains("clone"))
        #expect(output.contains("Clone 1"))
        #expect(!output.contains("No clones detected."))
    }

    @Test("Given directory with no duplicates, when running full pipeline, then all reporters indicate zero clones")
    func noDuplicatesAllFormats() async throws {
        let tempDir = createTempDirectory(prefix: "EndToEndAnalysis")
        defer { removeTempDirectory(tempDir) }

        try uniqueSourceA.write(toFile: tempDir + "/A.swift", atomically: true, encoding: .utf8)
        try uniqueSourceB.write(toFile: tempDir + "/B.swift", atomically: true, encoding: .utf8)

        let result = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            cacheLabel: "no-dup"
        )

        #expect(result.cloneGroups.isEmpty)

        let textOutput = TextReporter().report(result)
        #expect(textOutput.contains("No clones detected"))

        let xcodeOutput = XcodeReporter().report(result)
        #expect(xcodeOutput.isEmpty)

        let htmlOutput = HtmlReporter().report(result)
        #expect(htmlOutput.contains("No clones detected."))
    }
}
