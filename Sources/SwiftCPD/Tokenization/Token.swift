struct Token: Sendable, Equatable, Hashable, Codable {

    let kind: TokenKind
    let text: String
    let location: SourceLocation
}
