import Foundation

@testable import swift_cpd

func loadCacheEnvelope(at directory: String) throws -> FileCache.Envelope {
    let url = URL(fileURLWithPath: directory).appendingPathComponent("cache.json")
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(FileCache.Envelope.self, from: data)
}
