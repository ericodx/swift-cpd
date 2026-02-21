import Foundation
import Testing

@testable import swift_cpd

@Suite("ConfigurationIntegration")
struct ConfigurationIntegrationTests {

    @Test(
        "Given high minimum token count, when analyzing, then fewer clones detected"
    )
    func highTokenThresholdReducesClones() async throws {
        let tempDir = createTempDirectory(prefix: "ConfigurationIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let lowThreshold = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheLabel: "low"
        )
        let highThreshold = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 500,
            minimumLineCount: 1,
            cacheLabel: "high"
        )

        #expect(!lowThreshold.cloneGroups.isEmpty)
        #expect(highThreshold.cloneGroups.isEmpty)
    }

    @Test(
        "Given high minimum line count, when analyzing, then fewer clones detected"
    )
    func highLineThresholdReducesClones() async throws {
        let tempDir = createTempDirectory(prefix: "ConfigurationIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let lowThreshold = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheLabel: "low-line"
        )
        let highThreshold = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 5,
            minimumLineCount: 500,
            cacheLabel: "high-line"
        )

        #expect(!lowThreshold.cloneGroups.isEmpty)
        #expect(highThreshold.cloneGroups.isEmpty)
    }

    @Test(
        "Given low thresholds, when analyzing duplicates, then clones detected"
    )
    func lowThresholdsDetectClones() async throws {
        let tempDir = createTempDirectory(prefix: "ConfigurationIntegration")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let result = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 1,
            minimumLineCount: 1,
            cacheLabel: "low-all"
        )

        #expect(!result.cloneGroups.isEmpty)
    }

    @Test(
        "Given default thresholds, when analyzing small duplicates, then no clones detected"
    )
    func defaultThresholdsSkipSmallDuplicates() async throws {
        let tempDir = createTempDirectory(prefix: "ConfigurationIntegration")
        defer { removeTempDirectory(tempDir) }

        let smallSource = """
            func a() -> Int {
                return 1
            }
            """

        try smallSource.write(
            toFile: tempDir + "/A.swift",
            atomically: true,
            encoding: .utf8
        )
        try smallSource.write(
            toFile: tempDir + "/B.swift",
            atomically: true,
            encoding: .utf8
        )

        let result = try await analyzeDirectory(
            tempDir,
            minimumTokenCount: 50,
            minimumLineCount: 5,
            cacheLabel: "default"
        )

        #expect(result.cloneGroups.isEmpty)
    }

    @Test(
        "Given multiple source paths, when analyzing, then discovers files from all paths"
    )
    func multipleSourcePaths() async throws {
        let tempDir = createTempDirectory(prefix: "ConfigurationIntegration")
        defer { removeTempDirectory(tempDir) }

        let dirA = tempDir + "/ModuleA"
        let dirB = tempDir + "/ModuleB"
        try FileManager.default.createDirectory(
            atPath: dirA,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            atPath: dirB,
            withIntermediateDirectories: true
        )

        let source = standardDuplicateSource
        try source.write(
            toFile: dirA + "/FileA.swift",
            atomically: true,
            encoding: .utf8
        )
        try source.write(
            toFile: dirB + "/FileB.swift",
            atomically: true,
            encoding: .utf8
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [dirA, dirB])

        #expect(files.count == 2)

        let cacheDir = tempDir + "/.swiftcpd-cache"
        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let pipelineResult = try await pipeline.analyze(files: files)

        #expect(!pipelineResult.cloneGroups.isEmpty)
    }
}
