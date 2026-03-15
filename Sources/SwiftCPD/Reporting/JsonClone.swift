struct JsonClone: Encodable {

    let fragments: [JsonFragment]
    let id: String
    let lineCount: Int
    let similarity: Double
    let tokenCount: Int
    let type: Int
}
