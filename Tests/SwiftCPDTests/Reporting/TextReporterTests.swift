import Testing

@testable import swift_cpd

@Suite("TextReporter")
struct TextReporterTests {

    let reporter = TextReporter()

    @Test("Given no clones, when reporting, then shows no clones message")
    func noClones() {
        let result = AnalysisResult(
            cloneGroups: [],
            filesAnalyzed: 42,
            executionTime: 0.45,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("No clones detected"))
        #expect(output.contains("42 files"))
    }

    @Test("Given one clone group, when reporting, then formats header and fragments")
    func singleClone() {
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
            filesAnalyzed: 10,
            executionTime: 0.85,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        #expect(output.contains("Found 1 clone(s)"))
        #expect(output.contains("Clone 1 (Type-1, 52 tokens, 8 lines):"))
        #expect(output.contains("A.swift:10-17"))
        #expect(output.contains("B.swift:22-29"))
    }

    @Test("Given multiple clone groups, when reporting, then sorts by type and numbers them")
    func multipleClonesAreSortedAndNumbered() throws {
        let clone1 = CloneGroup(
            type: .type2,
            tokenCount: 30,
            lineCount: 5,
            similarity: 85.0,
            fragments: [
                CloneFragment(file: "X.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2)
            ]
        )
        let clone2 = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 10,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "Y.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2)
            ]
        )
        let result = AnalysisResult(
            cloneGroups: [clone1, clone2],
            filesAnalyzed: 5,
            executionTime: 0.1,
            totalTokens: 500,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let output = reporter.report(result)

        let clone1Position = try #require(output.range(of: "Clone 1")).lowerBound
        let clone2Position = try #require(output.range(of: "Clone 2")).lowerBound

        #expect(clone1Position < clone2Position)
        #expect(output.contains("Type-1"))
        #expect(output.contains("Type-2"))
    }
}
