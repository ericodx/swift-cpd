struct CloneFragment: Sendable, Equatable, Hashable {

    let file: String
    let startLine: Int
    let endLine: Int
    let startColumn: Int
    let endColumn: Int
}

extension CloneFragment {

    init(file: String, tokens: [Token], startIndex: Int, endIndex: Int) {
        let firstToken = tokens[startIndex]
        let lastToken = tokens[endIndex]
        self.file = file
        self.startLine = firstToken.location.line
        self.endLine = lastToken.location.line
        self.startColumn = firstToken.location.column
        self.endColumn = lastToken.location.column + lastToken.text.count
    }

    init(_ indexed: IndexedBlock, files: [FileTokens]) {
        self.init(
            file: indexed.block.file,
            tokens: files[indexed.fileIndex].tokens,
            startIndex: indexed.block.startTokenIndex,
            endIndex: indexed.block.endTokenIndex
        )
    }
}
