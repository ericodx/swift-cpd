import Foundation
import Testing

@testable import swift_cpd

@Suite("WorkingTreeSourceReader")
struct WorkingTreeSourceReaderTests {

    private let reader = WorkingTreeSourceReader()

    @Test("Given UTF-8 file on disk, when reading, then returns its bytes (G4)")
    func readsUtf8File() throws {
        let tempDir = createTempDirectory(prefix: "WorkingTreeSourceReader")
        defer { removeTempDirectory(tempDir) }

        let filePath = tempDir + "/A.swift"
        let contents = "let x = 1\n"
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)

        let data = try reader.read(file: filePath)

        #expect(String(data: data, encoding: .utf8) == contents)
    }

    @Test("Given file with arbitrary bytes, when reading, then returns raw data without UTF-8 assumption (G11)")
    func readsArbitraryBytes() throws {
        let tempDir = createTempDirectory(prefix: "WorkingTreeSourceReader")
        defer { removeTempDirectory(tempDir) }

        let filePath = tempDir + "/Binary.swift"
        let bytes = Data([0x00, 0xFF, 0xFE, 0xC3, 0x28, 0x80])
        createFile(at: filePath, content: bytes)

        let data = try reader.read(file: filePath)

        #expect(data == bytes)
    }

    @Test("Given missing file, when reading, then throws")
    func missingFileThrows() {
        let missing = createTempDirectory(prefix: "WorkingTreeSourceReader") + "/does-not-exist.swift"
        defer { removeTempDirectory((missing as NSString).deletingLastPathComponent) }

        #expect(throws: (any Error).self) {
            _ = try reader.read(file: missing)
        }
    }
}
