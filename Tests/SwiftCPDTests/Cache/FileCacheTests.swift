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

        await cache.store(key: CacheKey(file: "A.swift"), entry: entry)
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "abc123")

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

        await cache.store(key: CacheKey(file: "A.swift"), entry: entry)
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "different_hash")

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
        await cacheA.store(key: CacheKey(file: "A.swift"), entry: entry)
        await cacheA.save(to: tempDir)

        let cacheB = FileCache()
        await cacheB.load(from: tempDir)
        let result = await cacheB.lookup(key: CacheKey(file: "A.swift"), contentHash: "abc123")

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
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "abc123")

        #expect(result == nil)
    }

    @Test("Given nonexistent directory, when loading, then starts empty")
    func loadFromNonexistentDirectory() async {
        let cache = FileCache()
        await cache.load(from: "/nonexistent/path/\(UUID().uuidString)")
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "abc123")

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

        await cache.store(key: CacheKey(file: "A.swift"), entry: entry)
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

        await cache.store(key: CacheKey(file: "A.swift"), entry: entry)
        await cache.save(to: tempDir)
    }

    @Test("Given keys with same file but different resolvedSha, when stored, then coexist without collision")
    func compositeKeysCoexist() async {
        let cache = FileCache()
        let workingTreeEntry = CacheEntry(
            contentHash: "wt",
            tokens: [Token(kind: .keyword, text: "wt", location: location)],
            normalizedTokens: []
        )
        let refEntry = CacheEntry(
            contentHash: "ref",
            tokens: [Token(kind: .keyword, text: "ref", location: location)],
            normalizedTokens: []
        )

        await cache.store(key: CacheKey(file: "A.swift"), entry: workingTreeEntry)
        await cache.store(key: CacheKey(file: "A.swift", resolvedSha: "abc1234"), entry: refEntry)

        let wtResult = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "wt")
        let refResult = await cache.lookup(
            key: CacheKey(file: "A.swift", resolvedSha: "abc1234"),
            contentHash: "ref"
        )

        #expect(wtResult?.tokens.first?.text == "wt")
        #expect(refResult?.tokens.first?.text == "ref")
    }

    @Test("Given keyed by resolvedSha, when looking up with different sha, then misses")
    func resolvedShaIsolatesCache() async {
        let cache = FileCache()
        let entry = CacheEntry(
            contentHash: "h",
            tokens: [Token(kind: .keyword, text: "x", location: location)],
            normalizedTokens: []
        )

        await cache.store(key: CacheKey(file: "A.swift", resolvedSha: "sha1"), entry: entry)

        let sameSha = await cache.lookup(
            key: CacheKey(file: "A.swift", resolvedSha: "sha1"),
            contentHash: "h"
        )
        let otherSha = await cache.lookup(
            key: CacheKey(file: "A.swift", resolvedSha: "sha2"),
            contentHash: "h"
        )

        #expect(sameSha != nil)
        #expect(otherSha == nil)
    }

    @Test("Given saved cache, when loading, then envelope round-trip preserves composite keys")
    func envelopeRoundTrip() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_envelope_\(UUID().uuidString)")
            .path

        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let entry = CacheEntry(
            contentHash: "h",
            tokens: [Token(kind: .keyword, text: "let", location: location)],
            normalizedTokens: []
        )

        let writer = FileCache()
        await writer.store(key: CacheKey(file: "A.swift", resolvedSha: "deadbeef"), entry: entry)
        await writer.save(to: tempDir)

        let raw = try Data(contentsOf: URL(fileURLWithPath: tempDir + "/cache.json"))
        let json = try #require(try JSONSerialization.jsonObject(with: raw) as? [String: Any])

        #expect(json["schemaVersion"] as? Int == 2)
        let entries = try #require(json["entries"] as? [String: Any])
        #expect(entries["deadbeef|A.swift"] != nil)

        let reader = FileCache()
        await reader.load(from: tempDir)
        let result = await reader.lookup(
            key: CacheKey(file: "A.swift", resolvedSha: "deadbeef"),
            contentHash: "h"
        )

        #expect(result?.tokens.first?.text == "let")
    }

    @Test("Given a v1-format cache file on disk, when loading, then invalidates silently")
    func v1FormatInvalidates() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_v1_\(UUID().uuidString)")
            .path

        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let v1Payload = """
            {
              "A.swift": {
                "contentHash": "h",
                "tokens": [],
                "normalizedTokens": []
              }
            }
            """
        try v1Payload.write(
            toFile: tempDir + "/cache.json",
            atomically: true,
            encoding: .utf8
        )

        let cache = FileCache()
        await cache.load(from: tempDir)
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "h")

        #expect(result == nil)
    }

    @Test("Given envelope with wrong schemaVersion, when loading, then invalidates")
    func unknownSchemaVersionInvalidates() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache_v99_\(UUID().uuidString)")
            .path

        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let payload = """
            {
              "schemaVersion": 99,
              "entries": {
                "A.swift": {
                  "contentHash": "h",
                  "tokens": [],
                  "normalizedTokens": []
                }
              }
            }
            """
        try payload.write(
            toFile: tempDir + "/cache.json",
            atomically: true,
            encoding: .utf8
        )

        let cache = FileCache()
        await cache.load(from: tempDir)
        let result = await cache.lookup(key: CacheKey(file: "A.swift"), contentHash: "h")

        #expect(result == nil)
    }
}
