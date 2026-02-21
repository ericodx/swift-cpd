struct JsonReport: Encodable {

    let clones: [JsonClone]
    let metadata: JsonMetadata
    let summary: JsonSummary
    let version: String
}
