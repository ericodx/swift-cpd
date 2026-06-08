import Foundation
import Testing

@testable import swift_cpd

@Suite("FileHasher")
struct FileHasherTests {

    private let hasher = FileHasher()

    @Test("Given same file content, when hashing twice, then produces identical hash")
    func deterministic() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let filePath = tempDir.appendingPathComponent("hash_test_\(UUID().uuidString).swift").path

        try "let x = 1".write(toFile: filePath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: filePath) }

        let hashA = try hasher.hash(contentsOf: filePath)
        let hashB = try hasher.hash(contentsOf: filePath)

        #expect(hashA == hashB)
        #expect(hashA.count == 64)
    }

    @Test("Given different file contents, when hashing, then produces different hashes")
    func differentContent() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileA = tempDir.appendingPathComponent("hash_a_\(UUID().uuidString).swift").path
        let fileB = tempDir.appendingPathComponent("hash_b_\(UUID().uuidString).swift").path

        try "let x = 1".write(toFile: fileA, atomically: true, encoding: .utf8)
        try "var y = 2".write(toFile: fileB, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: fileA)
            try? FileManager.default.removeItem(atPath: fileB)
        }

        let hashA = try hasher.hash(contentsOf: fileA)
        let hashB = try hasher.hash(contentsOf: fileB)

        #expect(hashA != hashB)
    }

    @Test("Given known input, when hashing data, then matches reference SHA-256")
    func hashesDataAgainstKnownDigest() {
        let data = Data("abc".utf8)
        let expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

        #expect(hasher.hash(data: data) == expected)
    }

    @Test("Given same bytes, when hashing data and hashing file with same contents, then results match")
    func dataAndFileHashesAgree() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let filePath = tempDir.appendingPathComponent("hash_eq_\(UUID().uuidString).bin").path
        let data = Data([0x00, 0x01, 0x02, 0xFF, 0xFE])

        try data.write(to: URL(fileURLWithPath: filePath))
        defer { try? FileManager.default.removeItem(atPath: filePath) }

        let fileHash = try hasher.hash(contentsOf: filePath)
        let dataHash = hasher.hash(data: data)

        #expect(fileHash == dataHash)
        #expect(dataHash.count == 64)
    }

    @Test("Given empty data, when hashing, then returns SHA-256 of empty input")
    func hashesEmptyData() {
        let empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

        #expect(hasher.hash(data: Data()) == empty)
    }
}
