enum CloneGroupBuilder {

    static func buildFragment(
        file: String,
        tokens: [Token],
        startIndex: Int,
        endIndex: Int
    ) -> CloneFragment {
        let firstToken = tokens[startIndex]
        let lastToken = tokens[endIndex]

        return CloneFragment(
            file: file,
            startLine: firstToken.location.line,
            endLine: lastToken.location.line,
            startColumn: firstToken.location.column,
            endColumn: lastToken.location.column + lastToken.text.count
        )
    }

    static func buildFragment(
        _ indexed: IndexedBlock,
        files: [FileTokens]
    ) -> CloneFragment {
        buildFragment(
            file: indexed.block.file,
            tokens: files[indexed.fileIndex].tokens,
            startIndex: indexed.block.startTokenIndex,
            endIndex: indexed.block.endTokenIndex
        )
    }

    static func buildCloneGroup(
        type: CloneType,
        pair: IndexedBlockPair,
        files: [FileTokens],
        similarity: Double,
        minimumLineCount: Int
    ) -> CloneGroup? {
        let fragmentA = buildFragment(pair.blockA, files: files)
        let fragmentB = buildFragment(pair.blockB, files: files)

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

        let percentSimilarity = (similarity * 1000).rounded() / 10

        return CloneGroup(
            type: type,
            tokenCount: tokenCount,
            lineCount: lineCount,
            similarity: percentSimilarity,
            fragments: [fragmentA, fragmentB]
        )
    }
}
