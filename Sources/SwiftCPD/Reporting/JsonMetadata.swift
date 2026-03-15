struct JsonMetadata: Encodable {

    let configuration: JsonConfiguration
    let executionTimeMs: Int
    let filesAnalyzed: Int
    let timestamp: String
    let totalTokens: Int
}
