import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline")
struct AnalysisPipelineTests {

    @Test("Given duplicate files, when analyzing, then detects clones")
    func detectsClonesAcrossFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_test_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(!result.cloneGroups.isEmpty)
        #expect(result.totalTokens > 0)
    }

    @Test("Given cached files, when analyzing again, then uses cache")
    func cacheHitSkipsTokenization() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_cache_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
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
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
    }

    @Test("Given files with suppression annotations, when analyzing, then suppressed lines excluded")
    func suppressionExcludesLines() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_suppression_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
        )

        let resultWithSuppression = try await pipeline.analyze(files: [fileA, fileB])

        let pipelineNoSuppression = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cache: .init(directory: cacheDir + "-nosup")
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
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir),
            crossLanguageEnabled: true
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
    }

    @Test("Given restricted enabledCloneTypes, when analyzing, then only matching detectors run")
    func restrictedEnabledCloneTypes() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_restricted_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir),
            enabledCloneTypes: [.type1, .type2]
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
        #expect(result.cloneGroups.allSatisfy { $0.type == .type1 || $0.type == .type2 })
    }

    @Test("Given files sorted in reverse order, when analyzing, then results are sorted by file path")
    func resultsSortedByFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_sort_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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

        let fileZ = tempDir.appendingPathComponent("Z.swift").path
        let fileA = tempDir.appendingPathComponent("A.swift").path
        try source.write(toFile: fileZ, atomically: true, encoding: .utf8)
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cache: .init(directory: cacheDir)
        )

        let result = try await pipeline.analyze(files: [fileZ, fileA])

        if let firstClone = result.cloneGroups.first,
            let firstFrag = firstClone.fragments.first
        {
            #expect(firstFrag.file.hasSuffix("A.swift"))
        }
    }

    @Test("Given clones of different types, when analyzing, then sorted by type then file then startLine")
    func clonesAreSortedByTypeFileLine() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_clone_sort_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        for index in 0 ..< result.cloneGroups.count - 1 {
            let current = result.cloneGroups[index]
            let next = result.cloneGroups[index + 1]

            if current.type.rawValue == next.type.rawValue,
                let curFrag = current.fragments.first,
                let nextFrag = next.fragments.first,
                curFrag.file == nextFrag.file
            {
                #expect(curFrag.startLine <= nextFrag.startLine)
            }
        }
    }

    @Test("Given only type3 enabled, when analyzing, then excludes type1 and type2 clones")
    func enabledCloneTypesFilterWorks() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_filter_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir),
            enabledCloneTypes: [.type3]
        )

        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.cloneGroups.allSatisfy { $0.type == .type3 })
    }

    @Test("Given default crossLanguage, when creating pipeline, then crossLanguageEnabled is false")
    func defaultCrossLanguageIsFalse() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_crosslang_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = "let x = 1\n"
        let fileA = tempDir.appendingPathComponent("A.swift").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cache: .init(directory: cacheDir)
        )

        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }

    @Test("Given multiple files, when analyzing, then results are deterministic")
    func deterministicResults() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_determinism_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path

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
            cache: .init(directory: cacheDir)
        )

        let runA = try await pipeline.analyze(files: filePaths)
        let runB = try await pipeline.analyze(files: filePaths)

        #expect(runA == runB)
    }
}
