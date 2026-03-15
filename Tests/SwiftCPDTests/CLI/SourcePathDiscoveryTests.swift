import Foundation
import Testing

@testable import swift_cpd

@Suite("SourcePathDiscovery")
struct SourcePathDiscoveryTests {

    @Test("Given SPM layout with Sources/, when discovering, then returns Sources/")
    func spmLayout() throws {
        let root = createTempDirectory(prefix: "cpd-spm")
        defer { removeTempDirectory(root) }

        try FileManager.default.createDirectory(
            atPath: "\(root)/Sources/MyTarget",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/Sources/MyTarget/Foo.swift", content: Data("let x = 1".utf8))

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["Sources/"])
    }

    @Test("Given Xcode layout with named target folder, when discovering, then returns that folder")
    func xcodeLayout() throws {
        let root = createTempDirectory(prefix: "cpd-xcode")
        defer { removeTempDirectory(root) }

        try FileManager.default.createDirectory(
            atPath: "\(root)/MyApp",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/MyApp/AppDelegate.swift", content: Data("import UIKit".utf8))

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["MyApp/"])
    }

    @Test("Given multiple target folders with Swift files, when discovering, then returns all of them sorted")
    func multipleTargets() throws {
        let root = createTempDirectory(prefix: "cpd-multi")
        defer { removeTempDirectory(root) }

        for name in ["AppCore", "AppUI", "AppTests"] {
            try FileManager.default.createDirectory(
                atPath: "\(root)/\(name)",
                withIntermediateDirectories: true
            )
            createFile(at: "\(root)/\(name)/Stub.swift", content: Data())
        }

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["AppCore/", "AppTests/", "AppUI/"])
    }

    @Test("Given excluded folders like DerivedData and Pods, when discovering, then ignores them")
    func excludedFolders() throws {
        let root = createTempDirectory(prefix: "cpd-excluded")
        defer { removeTempDirectory(root) }

        for excluded in ["DerivedData", "Pods", ".build", "Carthage", "vendor"] {
            try FileManager.default.createDirectory(
                atPath: "\(root)/\(excluded)",
                withIntermediateDirectories: true
            )
            createFile(at: "\(root)/\(excluded)/File.swift", content: Data())
        }

        try FileManager.default.createDirectory(
            atPath: "\(root)/MyApp",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/MyApp/Main.swift", content: Data())

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["MyApp/"])
    }

    @Test("Given folder with no Swift files, when discovering, then ignores it")
    func folderWithoutSwiftFiles() throws {
        let root = createTempDirectory(prefix: "cpd-noswift")
        defer { removeTempDirectory(root) }

        try FileManager.default.createDirectory(
            atPath: "\(root)/Resources",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/Resources/image.png", content: Data())

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["Sources/"])
    }

    @Test("Given empty directory, when discovering, then falls back to Sources/")
    func emptyDirectoryFallback() {
        let root = createTempDirectory(prefix: "cpd-empty")
        defer { removeTempDirectory(root) }

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["Sources/"])
    }

    @Test("Given Swift files nested in subdirectory, when discovering, then still detects parent folder")
    func nestedSwiftFiles() throws {
        let root = createTempDirectory(prefix: "cpd-nested")
        defer { removeTempDirectory(root) }

        try FileManager.default.createDirectory(
            atPath: "\(root)/MyApp/SubGroup/Deep",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/MyApp/SubGroup/Deep/File.swift", content: Data())

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["MyApp/"])
    }

    @Test("Given regular file at root level alongside a directory, when discovering, then file is skipped")
    func regularFileAtRootIsSkipped() throws {
        let root = createTempDirectory(prefix: "cpd-rootfile")
        defer { removeTempDirectory(root) }

        createFile(at: "\(root)/README.md", content: Data())

        try FileManager.default.createDirectory(
            atPath: "\(root)/MyApp",
            withIntermediateDirectories: true
        )
        createFile(at: "\(root)/MyApp/Main.swift", content: Data())

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["MyApp/"])
    }

    @Test("Given non-existent root path, when discovering, then falls back to Sources/")
    func nonExistentRootFallsBack() {
        let paths = SourcePathDiscovery().discover(in: "/nonexistent/\(UUID().uuidString)")

        #expect(paths == ["Sources/"])
    }

    @Test("Given unreadable subdirectory, when discovering, then skips it and falls back to Sources/")
    func unreadableSubdirectorySkipped() throws {
        let root = createTempDirectory(prefix: "cpd-noperm")
        let restrictedDir = "\(root)/Restricted"
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o755)],
                ofItemAtPath: restrictedDir
            )
            removeTempDirectory(root)
        }

        try FileManager.default.createDirectory(atPath: restrictedDir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o111)],
            ofItemAtPath: restrictedDir
        )

        let paths = SourcePathDiscovery().discover(in: root)

        #expect(paths == ["Sources/"])
    }
}
