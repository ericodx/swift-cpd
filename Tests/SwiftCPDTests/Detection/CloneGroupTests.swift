import Testing

@testable import swift_cpd

@Suite("CloneGroup")
struct CloneGroupTests {

    @Test("Given a clone group, when accessing fields, then returns stored values")
    func fieldStorage() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 20, endLine: 30, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type2, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(group.type == .type2)
        #expect(group.tokenCount == 50)
        #expect(group.lineCount == 10)
        #expect(group.similarity == 100.0)
        #expect(group.fragments.count == 2)
    }

    @Test("Given two identical groups, when comparing, then they are equal")
    func equality() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2),
        ]

        let groupA = CloneGroup(type: .type1, tokenCount: 30, lineCount: 5, similarity: 100.0, fragments: fragments)
        let groupB = CloneGroup(type: .type1, tokenCount: 30, lineCount: 5, similarity: 100.0, fragments: fragments)

        #expect(groupA == groupB)
    }

    @Test("Given a Type-3 group, when accessing similarity, then returns partial similarity")
    func type3Similarity() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 15, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 10, endLine: 25, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type3, tokenCount: 80, lineCount: 15, similarity: 75.5, fragments: fragments)

        #expect(group.type == .type3)
        #expect(group.similarity == 75.5)
    }

    @Test("Given Type-3 group, when checking isStructural, then returns true")
    func type3IsStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type3, tokenCount: 50, lineCount: 10, similarity: 75.0, fragments: fragments)

        #expect(group.isStructural)
    }

    @Test("Given Type-4 group, when checking isStructural, then returns true")
    func type4IsStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type4, tokenCount: 50, lineCount: 10, similarity: 80.0, fragments: fragments)

        #expect(group.isStructural)
    }

    @Test("Given Type-1 group, when checking isStructural, then returns false")
    func type1IsNotStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isStructural)
    }

    @Test("Given Type-2 group, when checking isStructural, then returns false")
    func type2IsNotStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type2, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isStructural)
    }

    @Test("Given fragments in same file, when checking isSameFile, then returns true")
    func sameFileFragments() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "A.swift", startLine: 20, endLine: 30, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(group.isSameFile)
    }

    @Test("Given fragments in different files, when checking isSameFile, then returns false")
    func differentFileFragments() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isSameFile)
    }

    @Test("Given empty fragments, when checking isSameFile, then returns false")
    func emptyFragmentsIsSameFile() {
        let group = CloneGroup(type: .type1, tokenCount: 0, lineCount: 0, similarity: 100.0, fragments: [])

        #expect(!group.isSameFile)
    }
}
