import Testing

@testable import swift_cpd

@Suite("AnalysisResult Sorting")
struct AnalysisResultSortingMutationTests {

    @Test("Given groups with different types, when sorting, then lower rawValue first")
    func sortsByTypeAscending() {
        let groupType2 = makeCloneGroup(
            type: .type2, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )
        let groupType1 = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupType2, groupType1])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].type == .type1)
        #expect(sorted[1].type == .type2)
    }

    @Test("Given same type, different tokenCount, when sorting, then higher first")
    func sortsByTokenCountDescending() {
        let groupSmall = makeCloneGroup(
            type: .type1, tokenCount: 5,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )
        let groupLarge = makeCloneGroup(
            type: .type1, tokenCount: 20,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupSmall, groupLarge])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].tokenCount == 20)
        #expect(sorted[1].tokenCount == 5)
    }

    @Test("Given same type and tokenCount, different files, then alphabetical")
    func sortsByFileAscending() {
        let groupB = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "B.swift", startLine: 1, endLine: 5),
                makeFragment(file: "B.swift", startLine: 10, endLine: 15),
            ]
        )
        let groupA = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupB, groupA])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.file == "A.swift")
        #expect(sorted[1].fragments.first?.file == "B.swift")
    }

    @Test("Given same file, different startLine, then earlier first")
    func sortsByStartLineAscending() {
        let groupLate = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 50, endLine: 55),
                makeFragment(file: "A.swift", startLine: 60, endLine: 65),
            ]
        )
        let groupEarly = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupLate, groupEarly])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.startLine == 1)
        #expect(sorted[1].fragments.first?.startLine == 50)
    }

    @Test("Given equal type rawValues, when < vs <=, then no swap")
    func equalTypeRawValuesNoSwap() {
        let groupA = makeCloneGroup(
            type: .type1, tokenCount: 15,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )
        let groupB = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupA, groupB])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].tokenCount == 15)
        #expect(sorted[1].tokenCount == 10)
    }

    @Test("Given equal tokenCount, when > vs >=, then proceeds to file compare")
    func equalTokenCountProceedsToFileCompare() {
        let groupB = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "B.swift", startLine: 1, endLine: 5),
                makeFragment(file: "B.swift", startLine: 10, endLine: 15),
            ]
        )
        let groupA = makeCloneGroup(
            type: .type1, tokenCount: 10,
            fragments: [
                makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                makeFragment(file: "A.swift", startLine: 10, endLine: 15),
            ]
        )

        let result = makeAnalysisResult(cloneGroups: [groupB, groupA])
        let sorted = result.sortedCloneGroups

        #expect(sorted[0].fragments.first?.file == "A.swift")
    }

    @Test("Given nil first fragment, when sorting, then returns false")
    func nilFragmentsReturnFalse() {
        let group1 = makeCloneGroup(type: .type1, tokenCount: 10, fragments: [])
        let group2 = makeCloneGroup(type: .type1, tokenCount: 10, fragments: [])

        let result = makeAnalysisResult(cloneGroups: [group1, group2])
        let sorted = result.sortedCloneGroups

        #expect(sorted.count == 2)
    }
}
