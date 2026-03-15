struct SourceLocation: Sendable, Equatable, Hashable, Codable {

    let file: String
    let line: Int
    let column: Int
}
