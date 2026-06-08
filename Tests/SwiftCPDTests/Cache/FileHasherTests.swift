import Foundation
import Testing

@testable import swift_cpd

@Suite("FileHasher")
struct FileHasherTests {

    private let hasher = FileHasher()

    @Test("Given known input, when hashing data, then matches reference SHA-256")
    func hashesDataAgainstKnownDigest() {
        let data = Data("abc".utf8)
        let expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

        #expect(hasher.hash(data: data) == expected)
    }

    @Test("Given empty data, when hashing, then returns SHA-256 of empty input")
    func hashesEmptyData() {
        let empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

        #expect(hasher.hash(data: Data()) == empty)
    }
}
