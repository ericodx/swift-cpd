import Foundation
import Testing

@testable import swift_cpd

@Suite("BaselineStore")
struct BaselineStoreTests {

    let store = BaselineStore()

    @Test("Given clone groups, when creating entries, then fingerprints match group data")
    func entriesFromCloneGroups() throws {
        let groups = [
            CloneGroup(
                type: .type1,
                tokenCount: 50,
                lineCount: 8,
                similarity: 100.0,
                fragments: [
                    CloneFragment(file: "A.swift", startLine: 10, endLine: 17, startColumn: 1, endColumn: 2),
                    CloneFragment(file: "B.swift", startLine: 22, endLine: 29, startColumn: 1, endColumn: 2),
                ]
            )
        ]

        let entries = store.entriesFromCloneGroups(groups)

        #expect(entries.count == 1)

        let entry = try #require(entries.first)
        #expect(entry.type == 1)
        #expect(entry.tokenCount == 50)
        #expect(entry.fragmentFingerprints.count == 2)
        #expect(entry.fragmentFingerprints[0].file == "A.swift")
    }

    @Test("Given saved entries, when loading from same path, then round-trips correctly")
    func saveAndLoadRoundTrip() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 1,
                tokenCount: 50,
                lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 10, endLine: 17),
                    FragmentFingerprint(file: "B.swift", startLine: 22, endLine: 29),
                ]
            )
        ]

        try store.save(entries, to: tempFile)
        let loaded = try store.load(from: tempFile)

        #expect(loaded == entries)
    }

    @Test("Given baseline with known clones, when filtering, then removes known clones")
    func filterRemovesKnownClones() {
        let knownClone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 10, endLine: 17, startColumn: 1, endColumn: 2),
                CloneFragment(file: "B.swift", startLine: 22, endLine: 29, startColumn: 1, endColumn: 2),
            ]
        )
        let newClone = CloneGroup(
            type: .type2,
            tokenCount: 30,
            lineCount: 5,
            similarity: 85.0,
            fragments: [
                CloneFragment(file: "C.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2),
                CloneFragment(file: "D.swift", startLine: 10, endLine: 14, startColumn: 1, endColumn: 2),
            ]
        )

        let baseline = store.entriesFromCloneGroups([knownClone])
        let filtered = store.filterNewClones([knownClone, newClone], baseline: baseline)

        #expect(filtered.count == 1)
        #expect(filtered[0].type == .type2)
    }

    @Test("Given empty baseline, when filtering, then keeps all clones")
    func keepsNewClones() {
        let newClone = CloneGroup(
            type: .type1,
            tokenCount: 50,
            lineCount: 8,
            similarity: 100.0,
            fragments: [
                CloneFragment(file: "A.swift", startLine: 10, endLine: 17, startColumn: 1, endColumn: 2)
            ]
        )

        let emptyBaseline: Set<BaselineEntry> = []
        let filtered = store.filterNewClones([newClone], baseline: emptyBaseline)

        #expect(filtered.count == 1)
    }

    @Test("Given non-existent baseline file, when loading, then returns empty set")
    func missingFileReturnsEmptySet() throws {
        let loaded = try store.load(from: "/nonexistent/baseline.json")

        #expect(loaded.isEmpty)
    }

    @Test("Given entries with empty fragment fingerprints, when saving and sorting, then handles gracefully")
    func emptyFragmentFingerprints() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-empty-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(type: 1, tokenCount: 50, lineCount: 8, fragmentFingerprints: []),
            BaselineEntry(type: 1, tokenCount: 50, lineCount: 5, fragmentFingerprints: []),
        ]

        try store.save(entries, to: tempFile)
        let loaded = try store.load(from: tempFile)

        #expect(loaded.count == 2)
    }
}
