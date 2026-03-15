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
}
