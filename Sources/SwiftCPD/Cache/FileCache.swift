import Foundation

actor FileCache {

    init(
        encoder: @escaping @Sendable (Envelope) throws -> Data = { try JSONEncoder().encode($0) }
    ) {
        self.encoder = encoder
    }

    static let currentSchemaVersion = 2

    private var entries: [String: CacheEntry] = [:]
    private let encoder: @Sendable (Envelope) throws -> Data

    struct Envelope: Codable, Sendable {
        let schemaVersion: Int
        let entries: [String: CacheEntry]
    }

    func lookup(key: CacheKey, contentHash: String) -> CacheEntry? {
        guard
            let entry = entries[key.encoded],
            entry.contentHash == contentHash
        else {
            return nil
        }

        return entry
    }

    func store(key: CacheKey, entry: CacheEntry) {
        entries[key.encoded] = entry
    }

    func load(from directory: String) async {
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent("cache.json")

        let decoded: Envelope? = await Task.detached(priority: .utility) {
            guard
                FileManager.default.fileExists(atPath: fileURL.path),
                let data = try? Data(contentsOf: fileURL),
                let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                envelope.schemaVersion == FileCache.currentSchemaVersion
            else {
                return nil
            }

            return envelope
        }.value

        if let decoded {
            entries = decoded.entries
        }
    }

    func save(to directory: String) async {
        let envelope = Envelope(
            schemaVersion: Self.currentSchemaVersion,
            entries: entries
        )

        guard
            let data = try? encoder(envelope)
        else {
            return
        }

        await Task.detached(priority: .utility) {
            let directoryURL = URL(fileURLWithPath: directory)

            if !FileManager.default.fileExists(atPath: directoryURL.path) {
                try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }

            let fileURL = directoryURL.appendingPathComponent("cache.json")
            try? data.write(to: fileURL)
        }.value
    }
}
