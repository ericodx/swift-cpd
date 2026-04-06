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

    @Test("Given clone groups with different types, when sorting, then orders by type ascending")
    func sortsByTypeAscending() {
        let type2Clone = CloneGroup(
            type: .type2,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let type1Clone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [type2Clone, type1Clone])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].type == .type1)
        #expect(sorted[1].type == .type2)
    }

    @Test(
        "Given groups with same type but different token counts, when sorting, then orders by token count descending"
    )
    func sortsByTokenCountDescending() {
        let smallClone = CloneGroup(
            type: .type1,
            tokenCount: 30,
            lineCount: 3,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 3, startColumn: 1, endColumn: 10)]
        )
        let largeClone = CloneGroup(
            type: .type1,
            tokenCount: 80,
            lineCount: 8,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [smallClone, largeClone])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].tokenCount == 80)
        #expect(sorted[1].tokenCount == 30)
    }

    @Test(
        "Given groups with same type and token count but different files, when sorting, then orders by file ascending"
    )
    func sortsByFileAscending() {
        let cloneFileZ = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "z.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let cloneA = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneFileZ, cloneA])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.file == "a.swift")
        #expect(sorted[1].fragments.first?.file == "z.swift")
    }

    @Test(
        "Given clone groups with same type, token count, and file, when sorting, then orders by start line ascending"
    )
    func sortsByStartLineAscending() {
        let cloneLate = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 100, endLine: 105, startColumn: 1, endColumn: 10)]
        )
        let cloneEarly = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 10, endLine: 15, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneLate, cloneEarly])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.startLine == 10)
        #expect(sorted[1].fragments.first?.startLine == 100)
    }

    @Test("Given clone groups with equal types, when sorting, then does not treat equal type as less than")
    func equalTypesDoNotSortByType() {
        let cloneA = CloneGroup(
            type: .type1,
            tokenCount: 80,
            lineCount: 8,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 8, startColumn: 1, endColumn: 10)]
        )
        let cloneB = CloneGroup(
            type: .type1,
            tokenCount: 30,
            lineCount: 3,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 3, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneA, cloneB])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].tokenCount == 80)
        #expect(sorted[1].tokenCount == 30)
    }

    @Test(
        "Given groups with equal token counts, when sorting, then does not treat equal token count as greater than"
    )
    func equalTokenCountsDoNotSortByTokenCount() {
        let cloneFileZ = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "z.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let cloneA = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneFileZ, cloneA])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.file == "a.swift")
        #expect(sorted[1].fragments.first?.file == "z.swift")
    }

    @Test("Given clone groups with equal files, when sorting, then does not treat equal file as less than")
    func equalFilesDoNotSortByFile() {
        let cloneLate = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "same.swift", startLine: 50, endLine: 55, startColumn: 1, endColumn: 10)]
        )
        let cloneEarly = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "same.swift", startLine: 10, endLine: 15, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneLate, cloneEarly])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.startLine == 10)
        #expect(sorted[1].fragments.first?.startLine == 50)
    }

    @Test(
        "Given one group with empty fragments and one with fragments, when sorting, then empty fragments not first"
    )
    func emptyFragmentsReturnsFalseNotTrue() {
        let withFragments = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let withoutFragments = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: []
        )
        let result = makeResult(cloneGroups: [withoutFragments, withFragments])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.isEmpty)
        #expect(sorted[1].fragments.count == 1)
    }

    @Test("Given clone groups with equal start lines, when sorting, then treats them as equal and preserves order")
    func equalStartLinesPreserveOrder() {
        let cloneA = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 10, endLine: 15, startColumn: 1, endColumn: 10)]
        )
        let cloneB = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 90.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 10, endLine: 15, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [cloneA, cloneB])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].similarity == 100.0)
        #expect(sorted[1].similarity == 90.0)
    }

    @Test("Given all four clone types, when sorting, then produces exact order type1 type2 type3 type4")
    func sortsFourTypesInOrder() {
        let type4 = CloneGroup(
            type: .type4,
            tokenCount: 50,
            lineCount: 5,
            similarity: 80.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let type2 = CloneGroup(
            type: .type2,
            tokenCount: 50,
            lineCount: 5,
            similarity: 95.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let type3 = CloneGroup(
            type: .type3,
            tokenCount: 50,
            lineCount: 5,
            similarity: 85.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let type1 = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 5,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [type4, type2, type3, type1])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0].type == .type1)
        #expect(sorted[1].type == .type2)
        #expect(sorted[2].type == .type3)
        #expect(sorted[3].type == .type4)
    }

    @Test("Given complex mix of clone groups, when sorting, then applies all sort criteria in correct priority")
    func sortsByAllCriteriaInPriority() {
        let groupA = CloneGroup(
            type: .type2,
            tokenCount: 40,
            lineCount: 4,
            similarity: 90.0,
            fragments: [CloneFragment(file: "b.swift", startLine: 20, endLine: 24, startColumn: 1, endColumn: 10)]
        )
        let groupB = CloneGroup(
            type: .type1,
            tokenCount: 30,
            lineCount: 3,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 1, endLine: 3, startColumn: 1, endColumn: 10)]
        )
        let groupC = CloneGroup(
            type: .type1,
            tokenCount: 60,
            lineCount: 6,
            similarity: 100.0,
            fragments: [CloneFragment(file: "c.swift", startLine: 10, endLine: 16, startColumn: 1, endColumn: 10)]
        )
        let cloneGroupD = CloneGroup(
            type: .type1,
            tokenCount: 60,
            lineCount: 6,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 5, endLine: 11, startColumn: 1, endColumn: 10)]
        )
        let cloneGroupE = CloneGroup(
            type: .type1,
            tokenCount: 60,
            lineCount: 6,
            similarity: 100.0,
            fragments: [CloneFragment(file: "a.swift", startLine: 50, endLine: 56, startColumn: 1, endColumn: 10)]
        )
        let result = makeResult(cloneGroups: [groupA, groupB, groupC, cloneGroupD, cloneGroupE])

        let sorted = result.sortedCloneGroups

        #expect(sorted[0] == cloneGroupD)
        #expect(sorted[1] == cloneGroupE)
        #expect(sorted[2] == groupC)
        #expect(sorted[3] == groupB)
        #expect(sorted[4] == groupA)
    }

    private func makeResult(cloneGroups: [CloneGroup]) -> AnalysisResult {
        AnalysisResult(
            cloneGroups: cloneGroups,
            filesAnalyzed: 1,
            executionTime: 0.1,
            totalTokens: 100,
            minimumTokenCount: 10,
            minimumLineCount: 1
        )
    }
}
