import Testing

@testable import swift_cpd

@Suite("HtmlReporter")
struct HtmlReporterTests {

    let reporter = HtmlReporter()

    @Test("Given clones, when reporting, then output contains valid HTML structure")
    func validHtmlStructure() {
        let clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("<!DOCTYPE html>"))
        #expect(output.contains("</html>"))
    }

    @Test("Given clones, when reporting, then output contains clone type and fragment details")
    func containsCloneDetails() {
        let clone = CloneGroup(
            type: .type2,
            tokenCount: 87,
            lineCount: 12,
            similarity: 90.0,
            fragments: [
                CloneFragment(file: "API.swift", startLine: 45, endLine: 56, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("Type-2"))
        #expect(output.contains("87 tokens"))
        #expect(output.contains("API.swift:45-56"))
    }

    @Test("Given no clones, when reporting, then shows no clones detected message")
    func noClonesMessage() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("No clones detected"))
        #expect(output.contains("0 clone(s)"))
    }
}
