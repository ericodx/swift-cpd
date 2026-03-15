import Foundation
import Testing

@testable import swift_cpd

@Suite("FileCache")
struct FileCacheTests {

    private let location = SourceLocation(file: "test.swift", line: 1, column: 1)

    @Test("Given a stored entry, when looking up with matching hash, then returns entry")
    func lookupHit() async {
        let cache = FileCache()
        let entry = CacheEntry(
            contentHash: "abc123",
            tokens: [Token(kind: .keyword, text: "let", location: location)],
            normalizedTokens: [Token(kind: .keyword, text: "let", location: location)]
        )

        await cache.store(file: "A.swift", entry: entry)
        let result = await cache.lookup(file: "A.swift", contentHash: "abc123")

        #expect(result != nil)
        #expect(result?.tokens.count == 1)
    }

    @Test("Given a stored entry, when looking up with wrong hash, then returns nil")
    func lookupMiss() async {
        let cache = FileCache()
        let entry = CacheEntry(
            contentHash: "abc123",
            tokens: [Token(kind: .keyword, text: "let", location: location)],
            normalizedTokens: [Token(kind: .keyword, text: "let", location: location)]
        )

        await cache.store(file: "A.swift", entry: entry)
        let result = await cache.lookup(file: "A.swift", contentHash: "different_hash")

        #expect(result == nil)
    }

    @Test("Given a saved cache, when loading from disk, then restores entries")
    func saveAndLoadRoundTrip() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_test_\(UUID().uuidString)")
            .path

        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let entry = CacheEntry(
            contentHash: "abc123",
            tokens: [Token(kind: .identifier, text: "x", location: location)],
            normalizedTokens: [Token(kind: .identifier, text: "$ID", location: location)]
        )

        let cacheA = FileCache()
        await cacheA.store(file: "A.swift", entry: entry)
        await cacheA.save(to: tempDir)

        let cacheB = FileCache()
        await cacheB.load(from: tempDir)
        let result = await cacheB.lookup(file: "A.swift", contentHash: "abc123")

        #expect(result != nil)
        #expect(result?.tokens.first?.text == "x")
        #expect(result?.normalizedTokens.first?.text == "$ID")
    }

    @Test("Given corrupted cache file, when loading, then ignores and starts empty")
    func corruptedCacheIgnored() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_corrupt_\(UUID().uuidString)")
            .path

        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        try? FileManager.default.createDirectory(
            atPath: tempDir,
            withIntermediateDirectories: true
        )
        try? "not valid json {{{".write(
            toFile: tempDir + "/cache.json",
            atomically: true,
            encoding: .utf8
        )

        let cache = FileCache()
        await cache.load(from: tempDir)
        let result = await cache.lookup(file: "A.swift", contentHash: "abc123")

        #expect(result == nil)
    }

    @Test("Given nonexistent directory, when loading, then starts empty")
    func loadFromNonexistentDirectory() async {
        let cache = FileCache()
        await cache.load(from: "/nonexistent/path/\(UUID().uuidString)")
        let result = await cache.lookup(file: "A.swift", contentHash: "abc123")

        #expect(result == nil)
    }

    @Test("Given an encoder that throws, when saving, then does not write the cache file")
    func saveSkipsWriteWhenEncodingFails() async {
        struct EncodeFailure: Error {}

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_encode_fail_\(UUID().uuidString)")
            .path

        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let cache = FileCache(encoder: { _ in throw EncodeFailure() })
        let entry = CacheEntry(
            contentHash: "abc123",
            tokens: [Token(kind: .keyword, text: "let", location: location)],
            normalizedTokens: [Token(kind: .keyword, text: "let", location: location)]
        )

        await cache.store(file: "A.swift", entry: entry)
        await cache.save(to: tempDir)

        #expect(!FileManager.default.fileExists(atPath: tempDir + "/cache.json"))
    }

    @Test("Given read-only directory, when saving, then does not crash")
    func saveToReadOnlyDirectory() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_readonly_\(UUID().uuidString)")
            .path

        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: tempDir
            )
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        try? FileManager.default.createDirectory(
            atPath: tempDir,
            withIntermediateDirectories: true
        )
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: tempDir
        )

        let cache = FileCache()
        let entry = CacheEntry(
            contentHash: "abc123",
            tokens: [Token(kind: .keyword, text: "let", location: location)],
            normalizedTokens: [Token(kind: .keyword, text: "let", location: location)]
        )

        await cache.store(file: "A.swift", entry: entry)
        await cache.save(to: tempDir)
    }
}
