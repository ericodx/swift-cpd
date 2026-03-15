struct FragmentFingerprint: Sendable, Codable, Equatable, Hashable {

    let file: String
    let startLine: Int
    let endLine: Int
}
