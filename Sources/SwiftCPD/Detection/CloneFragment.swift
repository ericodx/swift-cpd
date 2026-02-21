struct CloneFragment: Sendable, Equatable, Hashable {

    let file: String
    let startLine: Int
    let endLine: Int
    let startColumn: Int
    let endColumn: Int
}
