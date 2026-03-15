enum CloneGroupDeduplicator {

    static func deduplicate(_ clones: [CloneGroup]) -> [CloneGroup] {
        var unique: [CloneGroup] = []

        for clone in clones {
            let isDuplicate = unique.contains { existing in
                isSubsumed(clone, by: existing)
            }

            if !isDuplicate {
                unique.append(clone)
            }
        }

        return unique
    }

    private static func isSubsumed(_ clone: CloneGroup, by other: CloneGroup) -> Bool {
        zip(clone.fragments, other.fragments).allSatisfy { fragA, fragB in
            fragA.file == fragB.file
                && fragA.startLine >= fragB.startLine
                && fragA.endLine <= fragB.endLine
        }
    }
}
