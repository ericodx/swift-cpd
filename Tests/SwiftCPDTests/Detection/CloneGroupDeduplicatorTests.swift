import Testing

@testable import swift_cpd

@Suite("CloneGroupDeduplicator")
struct CloneGroupDeduplicatorTests {

    private func makeFragment(file: String, startLine: Int, endLine: Int) -> CloneFragment {
        CloneFragment(file: file, startLine: startLine, endLine: endLine, startColumn: 1, endColumn: 2)
    }

    private func makeGroup(fragments: [CloneFragment]) -> CloneGroup {
        CloneGroup(type: .type1, tokenCount: 10, lineCount: 5, similarity: 100.0, fragments: fragments)
    }

    @Test("Given empty input, when deduplicating, then returns empty array")
    func emptyInput() {
        let result = CloneGroupDeduplicator.deduplicate([])

        #expect(result.isEmpty)
    }

    @Test("Given single group, when deduplicating, then returns that group")
    func singleGroup() {
        let group = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 10),
            makeFragment(file: "B.swift", startLine: 1, endLine: 10),
        ])

        let result = CloneGroupDeduplicator.deduplicate([group])

        #expect(result.count == 1)
    }

    @Test("Given clone subsumed by another with same file, when deduplicating, then removes subsumed clone")
    func sameFileSubsumption() {
        let larger = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 20),
            makeFragment(file: "B.swift", startLine: 1, endLine: 20),
        ])
        let smaller = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([larger, smaller])

        #expect(result.count == 1)
        #expect(result[0] == larger)
    }

    @Test("Given clone with different file than existing, when deduplicating, then keeps both")
    func differentFileNotSubsumed() {
        let groupA = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 20),
            makeFragment(file: "B.swift", startLine: 1, endLine: 20),
        ])
        let groupB = makeGroup(fragments: [
            makeFragment(file: "C.swift", startLine: 1, endLine: 10),
            makeFragment(file: "B.swift", startLine: 1, endLine: 10),
        ])

        let result = CloneGroupDeduplicator.deduplicate([groupA, groupB])

        #expect(result.count == 2)
    }

    @Test("Given clone with exactly matching start and end lines, when deduplicating, then treats as subsumed")
    func exactBoundaryStartAndEndLinesAreSubsumed() {
        let outer = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])
        let inner = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([outer, inner])

        #expect(result.count == 1)
    }

    @Test("Given clone with startLine equal to existing startLine, when deduplicating, then treats as subsumed")
    func startLineEqualBoundary() {
        let outer = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 20),
            makeFragment(file: "B.swift", startLine: 5, endLine: 20),
        ])
        let inner = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([outer, inner])

        #expect(result.count == 1)
        #expect(result[0] == outer)
    }

    @Test("Given clone with endLine equal to existing endLine, when deduplicating, then treats as subsumed")
    func endLineEqualBoundary() {
        let outer = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 15),
            makeFragment(file: "B.swift", startLine: 1, endLine: 15),
        ])
        let inner = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([outer, inner])

        #expect(result.count == 1)
        #expect(result[0] == outer)
    }

    @Test("Given clone with startLine before existing startLine, when deduplicating, then keeps both")
    func startLineBeforeExistingNotSubsumed() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 20),
            makeFragment(file: "B.swift", startLine: 5, endLine: 20),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 3, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }

    @Test("Given clone with endLine after existing endLine, when deduplicating, then keeps both")
    func endLineAfterExistingNotSubsumed() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 15),
            makeFragment(file: "B.swift", startLine: 1, endLine: 15),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 18),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }

    @Test("Given clone where file matches but startLine fails, when deduplicating, then keeps both")
    func fileMatchesButStartLineExceedsRange() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 10, endLine: 20),
            makeFragment(file: "B.swift", startLine: 10, endLine: 20),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 10, endLine: 20),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }

    @Test("Given clone where file matches but endLine fails, when deduplicating, then keeps both")
    func fileMatchesButEndLineExceedsRange() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 15),
            makeFragment(file: "B.swift", startLine: 1, endLine: 15),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 20),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }

    @Test("Given clone where only one fragment has matching file, when deduplicating, then keeps both")
    func oneFragmentFileMatchesOtherDoesNot() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 1, endLine: 20),
            makeFragment(file: "B.swift", startLine: 1, endLine: 20),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "C.swift", startLine: 5, endLine: 15),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }

    @Test(
        "Given clone where one fragment startLine equals but other endLine exceeds, when deduplicating, then keeps both"
    )
    func mixedBoundaryConditionsNotSubsumed() {
        let existing = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 15),
        ])
        let candidate = makeGroup(fragments: [
            makeFragment(file: "A.swift", startLine: 5, endLine: 15),
            makeFragment(file: "B.swift", startLine: 5, endLine: 16),
        ])

        let result = CloneGroupDeduplicator.deduplicate([existing, candidate])

        #expect(result.count == 2)
    }
}
