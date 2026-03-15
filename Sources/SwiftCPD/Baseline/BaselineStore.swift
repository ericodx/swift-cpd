import Foundation

struct BaselineStore: Sendable {

    func load(from filePath: String) throws -> Set<BaselineEntry> {
        let url = URL(fileURLWithPath: filePath)

        guard
            FileManager.default.fileExists(atPath: filePath)
        else {
            return []
        }

        let data = try Data(contentsOf: url)
        let entries = try JSONDecoder().decode([BaselineEntry].self, from: data)
        return Set(entries)
    }

    func save(_ entries: Set<BaselineEntry>, to filePath: String) throws {
        let sorted = entries.sorted { lhs, rhs in
            if lhs.type != rhs.type {
                return lhs.type < rhs.type
            }

            if lhs.tokenCount != rhs.tokenCount {
                return lhs.tokenCount > rhs.tokenCount
            }

            guard
                let lhsFirst = lhs.fragmentFingerprints.first,
                let rhsFirst = rhs.fragmentFingerprints.first
            else {
                return false
            }

            return lhsFirst.file < rhsFirst.file
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sorted)

        let url = URL(fileURLWithPath: filePath)
        try data.write(to: url)
    }

    func entriesFromCloneGroups(_ groups: [CloneGroup]) -> Set<BaselineEntry> {
        Set(groups.map { entryFromCloneGroup($0) })
    }

    func filterNewClones(_ groups: [CloneGroup], baseline: Set<BaselineEntry>) -> [CloneGroup] {
        let currentEntries = entriesFromCloneGroups(groups)
        let newEntries = currentEntries.subtracting(baseline)

        return groups.filter { group in
            newEntries.contains(entryFromCloneGroup(group))
        }
    }

    private func entryFromCloneGroup(_ group: CloneGroup) -> BaselineEntry {
        BaselineEntry(
            type: group.type.rawValue,
            tokenCount: group.tokenCount,
            lineCount: group.lineCount,
            fragmentFingerprints: group.fragments.map { fragment in
                FragmentFingerprint(
                    file: fragment.file,
                    startLine: fragment.startLine,
                    endLine: fragment.endLine
                )
            }
        )
    }
}
