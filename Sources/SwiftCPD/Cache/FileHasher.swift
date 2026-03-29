import Foundation

#if canImport(CryptoKit)
    import CryptoKit
#else
    import Crypto
#endif

struct FileHasher: Sendable {

    func hash(contentsOf filePath: String) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
