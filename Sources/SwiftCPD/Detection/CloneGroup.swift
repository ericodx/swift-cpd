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

extension CloneGroup {

    init?(
        type: CloneType,
        pair: IndexedBlockPair,
        files: [FileTokens],
        similarity: Double,
        minimumLineCount: Int
    ) {
        let fragmentA = CloneFragment(pair.blockA, files: files)
        let fragmentB = CloneFragment(pair.blockB, files: files)

        let lineCount = max(
            fragmentA.endLine - fragmentA.startLine + 1,
            fragmentB.endLine - fragmentB.startLine + 1
        )

        guard
            lineCount >= minimumLineCount
        else {
            return nil
        }

        let tokenCount = max(
            pair.blockA.block.endTokenIndex - pair.blockA.block.startTokenIndex + 1,
            pair.blockB.block.endTokenIndex - pair.blockB.block.startTokenIndex + 1
        )

        self.type = type
        self.tokenCount = tokenCount
        self.lineCount = lineCount
        self.similarity = (similarity * 1000).rounded() / 10
        self.fragments = [fragmentA, fragmentB]
    }
}
