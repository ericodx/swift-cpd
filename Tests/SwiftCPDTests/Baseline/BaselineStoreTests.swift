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

    @Test("Given entries with different types, when saving, then sorts by type ascending")
    func sortsByTypeAscending() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-type-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 3, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 10, endLine: 15)
                ]),
            BaselineEntry(
                type: 2, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 20, endLine: 25)
                ]),
        ]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0].type == 1)
        #expect(saved[1].type == 2)
        #expect(saved[2].type == 3)
    }

    @Test("Given entries with equal types, when saving, then does not use type comparison for ordering")
    func equalTypeFallsThrough() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-equal-type-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 1, tokenCount: 30, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "B.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 80, lineCount: 10,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 10)
                ]),
        ]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0].tokenCount == 80)
        #expect(saved[1].tokenCount == 30)
    }

    @Test("Given entries with same type and different token counts, when saving, then sorts by token count descending")
    func sortsByTokenCountDescending() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-token-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 1, tokenCount: 30, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 80, lineCount: 10,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 10, endLine: 20)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 30, endLine: 38)
                ]),
        ]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0].tokenCount == 80)
        #expect(saved[1].tokenCount == 50)
        #expect(saved[2].tokenCount == 30)
    }

    @Test(
        "Given entries with same type and equal token counts, when saving, then does not use token count for ordering"
    )
    func equalTokenCountFallsThrough() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-equal-token-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "Z.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 10,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 10)
                ]),
        ]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0].fragmentFingerprints[0].file == "A.swift")
        #expect(saved[1].fragmentFingerprints[0].file == "Z.swift")
    }

    @Test(
        "Given entries with same type and token count and empty fragments, when saving, then preserves stable order"
    )
    func emptyFragmentsReturnFalse() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-empty-frag-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entryA = BaselineEntry(type: 1, tokenCount: 50, lineCount: 8, fragmentFingerprints: [])
        let entryB = BaselineEntry(type: 1, tokenCount: 50, lineCount: 5, fragmentFingerprints: [])

        let entries: Set<BaselineEntry> = [entryA, entryB]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved.count == 2)
        #expect(saved.contains(entryA))
        #expect(saved.contains(entryB))
    }

    @Test(
        "Given one entry with empty fragments and one with fragments, when saving, then guard returns false for both"
    )
    func mixedEmptyAndNonEmptyFragments() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-mixed-frag-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entryWithFragments = BaselineEntry(
            type: 1, tokenCount: 50, lineCount: 8,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ])
        let entryWithoutFragments = BaselineEntry(type: 1, tokenCount: 50, lineCount: 5, fragmentFingerprints: [])

        let entries: Set<BaselineEntry> = [entryWithFragments, entryWithoutFragments]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved.count == 2)
        #expect(saved.contains(entryWithFragments))
        #expect(saved.contains(entryWithoutFragments))
    }

    @Test("Given entries with same type and token count and different files, when saving, then sorts by file ascending")
    func sortsByFirstFragmentFileAscending() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-file-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entries: Set<BaselineEntry> = [
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "Z.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]),
            BaselineEntry(
                type: 1, tokenCount: 50, lineCount: 8,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "M.swift", startLine: 1, endLine: 5)
                ]),
        ]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0].fragmentFingerprints[0].file == "A.swift")
        #expect(saved[1].fragmentFingerprints[0].file == "M.swift")
        #expect(saved[2].fragmentFingerprints[0].file == "Z.swift")
    }

    @Test("Given entries with same type and token count and equal files, when saving, then does not reorder by file")
    func equalFileNamesProduceStableOrder() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-equal-file-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entryA = BaselineEntry(
            type: 1, tokenCount: 50, lineCount: 8,
            fragmentFingerprints: [
                FragmentFingerprint(file: "Same.swift", startLine: 1, endLine: 5)
            ])
        let entryB = BaselineEntry(
            type: 1, tokenCount: 50, lineCount: 10,
            fragmentFingerprints: [
                FragmentFingerprint(file: "Same.swift", startLine: 10, endLine: 20)
            ])

        let entries: Set<BaselineEntry> = [entryA, entryB]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved.count == 2)
        #expect(saved.contains(entryA))
        #expect(saved.contains(entryB))
    }

    @Test("Given entries spanning all sort tiers, when saving, then applies type then token count then file ordering")
    func fullSortingPrecedence() throws {
        let tempFile = NSTemporaryDirectory() + "baseline-sort-full-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let entryType2 = BaselineEntry(
            type: 2, tokenCount: 100, lineCount: 10,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 10)
            ])
        let entryType1High = BaselineEntry(
            type: 1, tokenCount: 80, lineCount: 8,
            fragmentFingerprints: [
                FragmentFingerprint(file: "Z.swift", startLine: 1, endLine: 8)
            ])
        let entryType1LowFileA = BaselineEntry(
            type: 1, tokenCount: 30, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
            ])
        let entryType1LowFileM = BaselineEntry(
            type: 1, tokenCount: 30, lineCount: 5,
            fragmentFingerprints: [
                FragmentFingerprint(file: "M.swift", startLine: 1, endLine: 5)
            ])

        let entries: Set<BaselineEntry> = [entryType2, entryType1High, entryType1LowFileA, entryType1LowFileM]

        try store.save(entries, to: tempFile)
        let saved = try loadOrderedEntries(from: tempFile)

        #expect(saved[0] == entryType1High)
        #expect(saved[1] == entryType1LowFileA)
        #expect(saved[2] == entryType1LowFileM)
        #expect(saved[3] == entryType2)
    }

    private func loadOrderedEntries(from filePath: String) throws -> [BaselineEntry] {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try JSONDecoder().decode([BaselineEntry].self, from: data)
    }
}
