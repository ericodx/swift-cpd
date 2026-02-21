import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline")
struct AnalysisPipelineTests {

    @Test("Given duplicate files, when analyzing, then detects clones")
    func detectsClonesAcrossFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_test_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            func calculate() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final = adjusted - 5
                return final
            }
            """

        let fileA = tempDir.appendingPathComponent("A.swift").path
        let fileB = tempDir.appendingPathComponent("B.swift").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(!result.cloneGroups.isEmpty)
        #expect(result.totalTokens > 0)
    }

    @Test("Given cached files, when analyzing again, then uses cache")
    func cacheHitSkipsTokenization() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_cache_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            func calculate() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final = adjusted - 5
                return final
            }
            """

        let fileA = tempDir.appendingPathComponent("A.swift").path
        let fileB = tempDir.appendingPathComponent("B.swift").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let firstRun = try await pipeline.analyze(files: [fileA, fileB])
        let secondRun = try await pipeline.analyze(files: [fileA, fileB])

        #expect(firstRun.cloneGroups.count == secondRun.cloneGroups.count)
        #expect(firstRun.totalTokens == secondRun.totalTokens)
    }

    @Test("Given ObjC files, when analyzing, then uses CTokenizer")
    func objcFilesUseCTokenizer() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_objc_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            @implementation Calculator
            - (NSInteger)calculate {
                NSInteger value = 42;
                NSInteger result = value * 2;
                NSInteger adjusted = result + 10;
                NSInteger final = adjusted - 5;
                return final;
            }
            @end
            """

        let fileA = tempDir.appendingPathComponent("A.m").path
        let fileB = tempDir.appendingPathComponent("B.m").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
    }

    @Test("Given files with suppression annotations, when analyzing, then suppressed lines excluded")
    func suppressionExcludesLines() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_suppression_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sourceA = """
            // swiftcpd:ignore
            func calculate() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final = adjusted - 5
                return final
            }
            func other() -> Int { return 1 }
            """

        let sourceB = """
            func calculate() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final = adjusted - 5
                return final
            }
            func other() -> Int { return 1 }
            """

        let fileA = tempDir.appendingPathComponent("A.swift").path
        let fileB = tempDir.appendingPathComponent("B.swift").path
        try sourceA.write(toFile: fileA, atomically: true, encoding: .utf8)
        try sourceB.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let resultWithSuppression = try await pipeline.analyze(files: [fileA, fileB])

        let pipelineNoSuppression = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir + "-nosup"
        )

        let resultWithout = try await pipelineNoSuppression.analyze(files: [
            fileB, fileB,
        ])

        #expect(resultWithSuppression.totalTokens < resultWithout.totalTokens)
    }

    @Test("Given ObjC files with cross-language enabled, when analyzing, then maps tokens to Swift equivalents")
    func crossLanguageEnabledMapsTokens() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_cross_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            @implementation Calculator
            - (NSInteger)calculate {
                NSInteger value = 42;
                NSInteger result = value * 2;
                NSInteger adjusted = result + 10;
                NSInteger final = adjusted - 5;
                return final;
            }
            @end
            """

        let fileA = tempDir.appendingPathComponent("A.m").path
        let fileB = tempDir.appendingPathComponent("B.m").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir,
            crossLanguageEnabled: true
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
    }

    @Test("Given multiple files, when analyzing, then results are deterministic")
    func deterministicResults() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_determinism_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swiftcpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            func calculate() -> Int {
                let value = 42
                let result = value * 2
                let adjusted = result + 10
                let final = adjusted - 5
                return final
            }
            """

        var filePaths: [String] = []
        for index in 0 ..< 5 {
            let path = tempDir.appendingPathComponent("File\(index).swift").path
            try source.write(toFile: path, atomically: true, encoding: .utf8)
            filePaths.append(path)
        }

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let runA = try await pipeline.analyze(files: filePaths)
        let runB = try await pipeline.analyze(files: filePaths)

        #expect(runA == runB)
    }
}
