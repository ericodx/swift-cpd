struct YamlConfiguration: Sendable, Equatable {

    let minimumTokenCount: Int?
    let minimumLineCount: Int?
    let outputFormat: String?
    let paths: [String]?
    let maxDuplication: Double?
    let type3Similarity: Int?
    let type3TileSize: Int?
    let type3CandidateThreshold: Int?
    let type4Similarity: Int?
    let crossLanguageEnabled: Bool?
    let exclude: [String]?
    let inlineSuppressionTag: String?
    let enabledCloneTypes: [Int]?
    let ignoreSameFile: Bool?
    let ignoreStructural: Bool?
}
