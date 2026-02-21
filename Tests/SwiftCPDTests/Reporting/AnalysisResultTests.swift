import Testing

@testable import swift_cpd

@Suite("AnalysisResult")
struct AnalysisResultTests {

    @Test("Given clone groups with empty fragments, when sorting, then handles gracefully")
    func emptyFragmentsFallback() {
        let cloneA = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: []
        )
        let cloneB = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: []
        )
        let result = AnalysisResult(
            cloneGroups: [cloneA, cloneB],
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 50,
            minimumLineCount: 5
        )

        let sorted = result.sortedCloneGroups

        #expect(sorted.count == 2)
    }
}
