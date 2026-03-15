struct DetectionThresholds: Sendable {

    static let defaults = DetectionThresholds(
        type3Similarity: 70,
        type3TileSize: 5,
        type3CandidateThreshold: 30,
        type4Similarity: 80
    )

    let type3Similarity: Int
    let type3TileSize: Int
    let type3CandidateThreshold: Int
    let type4Similarity: Int
}
