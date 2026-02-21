struct CodeBlock: Sendable, Equatable {

    let file: String
    let startLine: Int
    let endLine: Int
    let startTokenIndex: Int
    let endTokenIndex: Int
}
