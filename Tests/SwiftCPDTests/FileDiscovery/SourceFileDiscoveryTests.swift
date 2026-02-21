import Foundation
import Testing

@testable import swift_cpd

@Suite("SourceFileDiscovery")
struct SourceFileDiscoveryTests {

    @Test("Given Swift-only mode, when finding files, then returns only swift files")
    func swiftOnlyMode() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/File.swift")
        createFile(at: tempDir + "/File.m")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("File.swift"))
    }

    @Test("Given cross-language mode, when finding files, then returns swift and C-family files")
    func crossLanguageMode() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/File.swift")
        createFile(at: tempDir + "/File.m")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: true)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 2)
    }

    @Test("Given .m files, when finding in cross-language mode, then includes them")
    func includesObjcFiles() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/ViewController.m")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: true)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix(".m"))
    }

    @Test("Given .mm files, when finding in cross-language mode, then includes them")
    func includesObjcppFiles() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/Bridge.mm")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: true)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix(".mm"))
    }

    @Test("Given .h files, when finding in cross-language mode, then includes them")
    func includesHeaderFiles() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/Header.h")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: true)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix(".h"))
    }

    @Test("Given .c and .cpp files, when finding in cross-language mode, then includes them")
    func includesCAndCppFiles() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/util.c")
        createFile(at: tempDir + "/engine.cpp")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: true)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 2)
    }

    @Test("Given DerivedData directory, when finding, then excludes it")
    func excludesDerivedData() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/DerivedData",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Source.swift")
        createFile(at: tempDir + "/DerivedData/Generated.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Source.swift"))
    }

    @Test("Given hidden directories, when finding, then excludes them")
    func excludesHiddenDirectories() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/.hidden",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Visible.swift")
        createFile(at: tempDir + "/.hidden/Hidden.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Visible.swift"))
    }

    @Test("Given single file path, when finding, then returns that file")
    func singleFilePath() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        let filePath = tempDir + "/Single.swift"
        createFile(at: filePath)

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [filePath])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Single.swift"))
    }

    @Test("Given non-existent path, when finding, then throws error")
    func nonExistentPathThrows() {
        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)

        #expect(throws: FileDiscoveryError.self) {
            try discovery.findSourceFiles(in: ["/nonexistent/path"])
        }
    }

    @Test("Given exclude pattern, when finding, then excludes matching files")
    func excludePatternFiltersFiles() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/Model.swift")
        createFile(at: tempDir + "/Model.generated.swift")

        let discovery = SourceFileDiscovery(
            crossLanguageEnabled: false,
            excludePatterns: ["*.generated.swift"]
        )
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Model.swift"))
    }

    @Test("Given exclude pattern for directory, when finding, then excludes entire directory")
    func excludePatternFiltersDirectories() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/Generated",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Source.swift")
        createFile(at: tempDir + "/Generated/Auto.swift")

        let discovery = SourceFileDiscovery(
            crossLanguageEnabled: false,
            excludePatterns: ["**/Generated/**"]
        )
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Source.swift"))
    }

    @Test("Given .build directory, when finding, then excludes it")
    func excludesBuildDirectory() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/.build",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Source.swift")
        createFile(at: tempDir + "/.build/Package.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Source.swift"))
    }

    @Test("Given .git directory, when finding, then excludes it")
    func excludesGitDirectory() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        try FileManager.default.createDirectory(
            atPath: tempDir + "/.git",
            withIntermediateDirectories: true
        )
        createFile(at: tempDir + "/Source.swift")
        createFile(at: tempDir + "/.git/config.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Source.swift"))
    }

    @Test("Given symbolic link to swift file, when finding, then excludes it")
    func excludesSymbolicLinks() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        let realFile = tempDir + "/Real.swift"
        let symlink = tempDir + "/Link.swift"
        createFile(at: realFile)
        try FileManager.default.createSymbolicLink(atPath: symlink, withDestinationPath: realFile)

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Real.swift"))
    }

    @Test("Given multiple files, when finding, then returns sorted paths")
    func sortedPaths() throws {
        let tempDir = createTempDirectory(prefix: "SourceFileDiscovery")
        defer { removeTempDirectory(tempDir) }

        createFile(at: tempDir + "/Zebra.swift")
        createFile(at: tempDir + "/Alpha.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 2)
        #expect(files[0].hasSuffix("Alpha.swift"))
        #expect(files[1].hasSuffix("Zebra.swift"))
    }

    @Test("Given relative path, when finding files, then resolves relative to current directory")
    func relativePathResolved() throws {
        let dirName = "SourceDiscoveryRelTest-" + UUID().uuidString
        let cwd = FileManager.default.currentDirectoryPath
        let fullPath = cwd + "/" + dirName

        try? FileManager.default.createDirectory(atPath: fullPath, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: fullPath) }

        createFile(at: fullPath + "/Test.swift")

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [dirName])

        #expect(files.count == 1)
    }
}
