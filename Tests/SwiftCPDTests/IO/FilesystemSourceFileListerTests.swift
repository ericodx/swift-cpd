import Foundation
import Testing

@testable import swift_cpd

@Suite("FilesystemSourceFileLister")
struct FilesystemSourceFileListerTests {

    @Test("Given directory with Swift files, when listing, then returns them all (G1)")
    func listsSwiftFilesUnderPath() throws {
        let tempDir = createTempDirectory(prefix: "FilesystemSourceFileLister")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/A.swift")
        createFile(at: tempDir + "/B.swift")

        let lister = FilesystemSourceFileLister(crossLanguageEnabled: false)
        let files = try lister.listFiles(in: [tempDir])

        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("A.swift") })
        #expect(files.contains { $0.hasSuffix("B.swift") })
    }

    @Test("Given exclude patterns, when listing, then omits matching files (G3)")
    func honoursExcludePatterns() throws {
        let tempDir = createTempDirectory(prefix: "FilesystemSourceFileLister")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/Generated",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Source.swift")
        createFile(at: tempDir + "/Generated/Auto.swift")

        let lister = FilesystemSourceFileLister(
            crossLanguageEnabled: false,
            excludePatterns: ["**/Generated/**"]
        )
        let files = try lister.listFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Source.swift"))
    }

    @Test("Given mixed extensions in Swift-only mode, when listing, then keeps only .swift (G12)")
    func filtersByExtension() throws {
        let tempDir = createTempDirectory(prefix: "FilesystemSourceFileLister")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/A.swift")
        createFile(at: tempDir + "/README.md")
        createFile(at: tempDir + "/Bridge.m")

        let lister = FilesystemSourceFileLister(crossLanguageEnabled: false)
        let files = try lister.listFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("A.swift"))
    }

    @Test("Given cross-language mode, when listing, then includes C-family files alongside Swift")
    func crossLanguageIncludesCFamily() throws {
        let tempDir = createTempDirectory(prefix: "FilesystemSourceFileLister")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/A.swift")
        createFile(at: tempDir + "/Bridge.m")

        let lister = FilesystemSourceFileLister(crossLanguageEnabled: true)
        let files = try lister.listFiles(in: [tempDir])

        #expect(files.count == 2)
    }
}
