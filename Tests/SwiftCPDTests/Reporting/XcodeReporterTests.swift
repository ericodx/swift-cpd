import Testing

@testable import swift_cpd

@Suite("XcodeReporter")
struct XcodeReporterTests {

    let reporter = XcodeReporter()

    @Test("Given one clone group, when reporting, then emits one warning per fragment")
    func warningPerFragment() {
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
            filesAnalyzed: 2,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 2)
    }

    @Test("Given clone group, when reporting, then matches Xcode diagnostic format")
    func xcodeFormatPattern() {
        let clone = CloneGroup(
            type: .type2,
            tokenCount: 87,
            lineCount: 12,
            similarity: 90.0,
            fragments: [
                CloneFragment(
                    file: "Sources/APIClient.swift", startLine: 45, endLine: 56, startColumn: 1, endColumn: 2
                ),
                CloneFragment(
                    file: "Sources/LegacyClient.swift", startLine: 102, endLine: 113, startColumn: 1, endColumn: 2
                ),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 2,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("Sources/APIClient.swift:45:1: warning:"))
        #expect(output.contains("\u{2014} also in"))
        #expect(output.contains("also in LegacyClient.swift:102"))
    }

    @Test("Given three fragments, when reporting, then each warning references all other fragments")
    func multiFragmentReferences() {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2),
                CloneFragment(file: "B.swift", startLine: 10, endLine: 17, startColumn: 1, endColumn: 2),
                CloneFragment(file: "C.swift", startLine: 20, endLine: 27, startColumn: 1, endColumn: 2),
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 3,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 3)
        #expect(lines[0].contains("B.swift:10, C.swift:20"))
    }

    @Test("Given no clones, when reporting, then output is empty")
    func emptyForNoClones() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.isEmpty)
    }
}
