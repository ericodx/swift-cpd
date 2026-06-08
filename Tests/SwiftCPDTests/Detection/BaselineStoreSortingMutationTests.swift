import Testing

@testable import swift_cpd

@Suite("BaselineStore Sorting")
struct BaselineStoreSortingMutationTests {

    @Test("Given different types, when saving and loading, then sorted ascending")
    func sortsByTypeAscending() throws {
        let tempPath = createTempDirectory(prefix: "baseline-type")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 2, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        #expect(loaded[0].type == 1)
        #expect(loaded[1].type == 2)
    }

    @Test("Given same type, different tokenCount, then descending")
    func sortsByTokenCountDescending() throws {
        let tempPath = createTempDirectory(prefix: "baseline-token")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 1, tokenCount: 5, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 20, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        #expect(loaded[0].tokenCount == 20)
        #expect(loaded[1].tokenCount == 5)
    }

    @Test("Given same type and tokenCount, different files, then alphabetical")
    func sortsByFileAscending() throws {
        let tempPath = createTempDirectory(prefix: "baseline-file")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "B.swift", startLine: 1, endLine: 5)
            ]
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        let firstFile = loaded[0].fragmentFingerprints.first!.file
        let secondFile = loaded[1].fragmentFingerprints.first!.file
        #expect(firstFile == "A.swift")
        #expect(secondFile == "B.swift")
    }

    @Test("Given empty fingerprints, when sorting, then returns false for stability")
    func emptyFingerprintsReturnFalse() throws {
        let tempPath = createTempDirectory(prefix: "baseline-empty")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: []
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 3,
            fragmentFingerprints: []
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        #expect(loaded.count == 2)
    }

    @Test("Given equal types, when < vs <=, then equal types preserve order")
    func equalTypesPreserveOrder() throws {
        let tempPath = createTempDirectory(prefix: "baseline-eq-type")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 1, tokenCount: 20, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        #expect(loaded[0].tokenCount == 20)
        #expect(loaded[1].tokenCount == 10)
    }

    @Test("Given equal tokenCount, when > vs >=, then proceeds to file sort")
    func equalTokenCountGoesToFileSort() throws {
        let tempPath = createTempDirectory(prefix: "baseline-eq-tok")
        defer { removeTempDirectory(tempPath) }
        let filePath = tempPath + "/baseline.json"
        let store = BaselineStore()

        let entry1 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "B.swift", startLine: 1, endLine: 5)
            ]
        )
        let entry2 = BaselineEntry(
            type: 1, tokenCount: 10, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ]
        )

        try store.save(Set([entry1, entry2]), to: filePath)
        let loaded = try loadOrderedEntries(from: filePath)

        let firstFile = loaded[0].fragmentFingerprints.first!.file
        #expect(firstFile == "A.swift")
    }
}
