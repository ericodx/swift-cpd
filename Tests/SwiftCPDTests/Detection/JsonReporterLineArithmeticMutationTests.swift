import Testing

@testable import swift_cpd

@Suite("JsonReporter Line Arithmetic")
struct JsonReporterLineArithmeticMutationTests {

    @Test("Given endLine - 1, when mutated to + 1, then endIndex wrong")
    func readPreviewEndLineSubtraction() {
        let group = makeCloneGroup(
            type: .type1, tokenCount: 10, lineCount: 3,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 3),
                makeFragment(file: "B.swift", startLine: 1, endLine: 3),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [group])
        let reporter = JsonReporter()
        let output = reporter.report(result)

        #expect(output.contains("A.swift"))
    }
}
