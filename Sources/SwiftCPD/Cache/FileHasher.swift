import CryptoKit
import Foundation

struct FileHasher: Sendable {

    func hash(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
