import CryptoKit
import Foundation

struct FileHasher: Sendable {

    func hash(contentsOf filePath: String) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return hash(data: data)
    }

    func hash(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
