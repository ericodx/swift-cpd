struct CloneGroup: Sendable, Equatable, Hashable {

    let type: CloneType
    let tokenCount: Int
    let lineCount: Int
    let similarity: Double
    let fragments: [CloneFragment]

    var isStructural: Bool {
        type == .type3 || type == .type4
    }

    var isSameFile: Bool {
        guard
            let first = fragments.first
        else {
            return false
        }

        return fragments.allSatisfy { $0.file == first.file }
    }
}
