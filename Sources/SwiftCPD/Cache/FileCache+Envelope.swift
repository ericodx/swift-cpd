extension FileCache {

    struct Envelope: Codable, Sendable {
        let schemaVersion: Int
        let entries: [String: CacheEntry]
    }
}
