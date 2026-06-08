struct JsonReport: Encodable {

    let clones: [JsonClone]
    let metadata: JsonMetadata
    let summary: JsonSummary
    let version: String
    let sourceRef: String?
    let resolvedSha: String?

    enum CodingKeys: String, CodingKey {
        case clones, metadata, resolvedSha, sourceRef, summary, version
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clones, forKey: .clones)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(summary, forKey: .summary)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(sourceRef, forKey: .sourceRef)
        try container.encodeIfPresent(resolvedSha, forKey: .resolvedSha)
    }
}
