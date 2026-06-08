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

    @Test("Given no clones with zero filtered count, when reporting, then does not show filtered message")
    func noClonesWithZeroFilteredCount() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            filteredCloneCount: 0
        )

        let output = reporter.report(result)

        #expect(!output.contains("filtered"))
    }

    @Test("Given multiple clones, when reporting, then clone numbers are sequential starting at 1")
    func cloneNumbersAreSequential() {
        let clone1 = CloneGroup(
            type: .type1, tokenCount: 50, lineCount: 8, similarity: 100.0,
            fragments: [CloneFragment(file: "A.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 2)]
        )
        let clone2 = CloneGroup(
            type: .type2, tokenCount: 30, lineCount: 5, similarity: 85.0,
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

        #expect(output.contains("Clone 1"))
        #expect(output.contains("Clone 2"))
        #expect(!output.contains("Clone 0"))
    }

    @Test("Given no clones with filtered clones, when reporting, then shows filtered count")
    func noClonesWithFilteredCount() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            filteredCloneCount: 3
        )

        let output = reporter.report(result)

        #expect(output.contains("No clones detected"))
        #expect(output.contains("3 clone(s) filtered by configuration"))
    }

    @Test("Given sourceRef set, when reporting, then summary header contains the ref")
    func headerShowsRefWhenSet() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 4,
            executionTime: 0.42,
            totalTokens: 200,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            sourceRef: "HEAD"
        )

        let output = reporter.report(result)

        #expect(output.contains("at HEAD"))
        #expect(output.contains("0 clone(s) found in 4 files (at HEAD, 0.42s)"))
    }

    @Test("Given no sourceRef, when reporting, then summary header omits the at-ref segment")
    func headerOmitsRefWhenAbsent() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 3,
            executionTime: 0.05,
            totalTokens: 50,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("0 clone(s) found in 3 files (0.05s)"))
        #expect(!output.contains("at "))
    }

    @Test("Given sourceRef with HTML-meaningful chars, when reporting, then header escapes them")
    func headerEscapesRef() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 1,
            executionTime: 0.01,
            totalTokens: 10,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            sourceRef: "feature/<script>"
        )

        let output = reporter.report(result)

        #expect(!output.contains("<script>"))
        #expect(output.contains("&lt;script&gt;"))
    }
}
