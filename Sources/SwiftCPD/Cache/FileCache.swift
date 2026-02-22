import Foundation

actor FileCache {

    private var entries: [String: CacheEntry] = [:]
    private let encoder: @Sendable ([String: CacheEntry]) throws -> Data

    init(encoder: @escaping @Sendable ([String: CacheEntry]) throws -> Data = { try JSONEncoder().encode($0) }) {
        self.encoder = encoder
    }

    func lookup(file: String, contentHash: String) -> CacheEntry? {
        guard
            let entry = entries[file],
            entry.contentHash == contentHash
        else {
            return nil
        }

        return entry
    }

    func store(file: String, entry: CacheEntry) {
        entries[file] = entry
    }

    func load(from directory: String) {
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent("cache.json")

        guard
            FileManager.default.fileExists(atPath: fileURL.path),
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([String: CacheEntry].self, from: data)
        else {
            return
        }

        entries = decoded
    }

    func save(to directory: String) {
        let directoryURL = URL(fileURLWithPath: directory)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        guard
            let data = try? encoder(entries)
        else {
            return
        }

        let fileURL = directoryURL.appendingPathComponent("cache.json")
        try? data.write(to: fileURL)
    }
}
