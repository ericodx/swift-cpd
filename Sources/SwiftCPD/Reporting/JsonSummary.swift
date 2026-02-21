struct JsonSummary: Encodable {

    let byType: JsonByType
    let duplicatedLines: Int
    let duplicatedTokens: Int
    let duplicationPercentage: Double
    let totalClones: Int
}
