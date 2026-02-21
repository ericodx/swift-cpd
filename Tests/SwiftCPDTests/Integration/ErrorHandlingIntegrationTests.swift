import Foundation
import Testing

@testable import swift_cpd

@Suite("ErrorHandlingIntegration")
struct ErrorHandlingIntegrationTests {

    @Test(
        "Given empty directory, when discovering files, then returns empty list"
    )
    func emptyDirectory() throws {
        let tempDir = createTempDirectory(prefix: "ErrorHandlingIntegration")
        defer { removeTempDirectory(tempDir) }

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.isEmpty)
    }

    @Test(
        "Given directory with only non-Swift files, when discovering, then returns empty list"
    )
    func nonSwiftFilesOnly() throws {
        let tempDir = createTempDirectory(prefix: "ErrorHandlingIntegration")
        defer { removeTempDirectory(tempDir) }

        FileManager.default.createFile(
            atPath: tempDir + "/readme.md",
            contents: Data("# Readme".utf8)
        )
        FileManager.default.createFile(
            atPath: tempDir + "/config.json",
            contents: Data("{}".utf8)
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.isEmpty)
    }

    @Test(
        "Given excluded directory names, when discovering, then skips them"
    )
    func excludedDirectories() throws {
        let tempDir = createTempDirectory(prefix: "ErrorHandlingIntegration")
        defer { removeTempDirectory(tempDir) }

        let derivedData = tempDir + "/DerivedData"
        let pods = tempDir + "/Pods"
        try FileManager.default.createDirectory(
            atPath: derivedData,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            atPath: pods,
            withIntermediateDirectories: true
        )

        let source = "func example() {}"
        try source.write(
            toFile: tempDir + "/Main.swift",
            atomically: true,
            encoding: .utf8
        )
        try source.write(
            toFile: derivedData + "/Generated.swift",
            atomically: true,
            encoding: .utf8
        )
        try source.write(
            toFile: pods + "/Pod.swift",
            atomically: true,
            encoding: .utf8
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Main.swift"))
    }

    @Test(
        "Given single Swift file with no duplicates, when analyzing, then returns zero clones"
    )
    func singleFileNoClones() async throws {
        let tempDir = createTempDirectory(prefix: "ErrorHandlingIntegration")
        defer { removeTempDirectory(tempDir) }

        let source = """
            func uniqueOperation() -> String {
                let greeting = "Hello, World!"
                let uppercased = greeting.uppercased()
                return uppercased
            }
            """

        try source.write(
            toFile: tempDir + "/Only.swift",
            atomically: true,
            encoding: .utf8
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])
        let cacheDir = tempDir + "/.swiftcpd-cache"

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let result = try await pipeline.analyze(files: files)

        #expect(result.cloneGroups.isEmpty)
    }

    @Test(
        "Given files with different content, when analyzing, then no false positives"
    )
    func noFalsePositives() async throws {
        let tempDir = createTempDirectory(prefix: "ErrorHandlingIntegration")
        defer { removeTempDirectory(tempDir) }

        let sourceA = """
            import Foundation

            struct NetworkClient {
                let session: URLSession

                func fetchData(from url: URL) async throws -> Data {
                    let (data, _) = try await session.data(from: url)
                    return data
                }
            }
            """

        let sourceB = """
            import Foundation

            struct FileParser {
                let decoder: JSONDecoder

                func parse<T: Decodable>(data: Data) throws -> T {
                    try decoder.decode(T.self, from: data)
                }

                func parseArray<T: Decodable>(data: Data) throws -> [T] {
                    try decoder.decode([T].self, from: data)
                }
            }
            """

        try sourceA.write(
            toFile: tempDir + "/NetworkClient.swift",
            atomically: true,
            encoding: .utf8
        )
        try sourceB.write(
            toFile: tempDir + "/FileParser.swift",
            atomically: true,
            encoding: .utf8
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])
        let cacheDir = tempDir + "/.swiftcpd-cache"

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 50,
            minimumLineCount: 5,
            cacheDirectory: cacheDir
        )

        let result = try await pipeline.analyze(files: files)

        #expect(result.cloneGroups.isEmpty)
    }
}
