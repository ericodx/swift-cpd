struct FileTokens: Sendable {

    let file: String
    let source: String
    let tokens: [Token]
    let normalizedTokens: [Token]
}
