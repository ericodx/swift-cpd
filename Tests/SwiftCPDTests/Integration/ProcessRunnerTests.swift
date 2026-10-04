import Foundation
import Testing

@Suite("ProcessRunner executable lookup")
struct ProcessRunnerTests {

    @Test("resolves the package root from a source file path")
    func resolvesPackageRoot() {
        let root = packageRoot(from: #filePath)

        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path))
        #expect(root.lastPathComponent != "TestSupport")
    }

    @Test("resolves swift-cpd under .build/debug of the package root")
    func resolvesExecutableUnderBuildDebug() throws {
        let url = try swiftCPDExecutableURL()
        let expected = packageRoot(from: #filePath)
            .appendingPathComponent(".build/debug/swift-cpd")

        #expect(url.path == expected.path)
        #expect(FileManager.default.isExecutableFile(atPath: url.path))
    }

    @Test("fails with the path tried when the executable is missing")
    func failsWithPathWhenMissing() throws {
        let fakeRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftCPDFakePackage-\(UUID().uuidString)")
        let sourceFile = fakeRoot.appendingPathComponent("Tests/Support/File.swift")
        try FileManager.default.createDirectory(
            at: sourceFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: fakeRoot.appendingPathComponent("Package.swift").path, contents: Data())
        defer { try? FileManager.default.removeItem(at: fakeRoot) }

        let error = #expect(throws: MissingExecutableError.self) {
            try swiftCPDExecutableURL(filePath: sourceFile.path)
        }

        let expectedPath = fakeRoot.appendingPathComponent(".build/debug/swift-cpd").path
        #expect(error?.path == expectedPath)
        #expect(error?.description.contains(expectedPath) == true)
    }
}
