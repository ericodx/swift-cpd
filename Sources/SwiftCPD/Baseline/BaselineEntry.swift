struct BaselineEntry: Sendable, Codable, Equatable, Hashable {

    let type: Int
    let tokenCount: Int
    let lineCount: Int
    let fragmentFingerprints: [FragmentFingerprint]
}
