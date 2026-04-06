import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline Sorting")
struct AnalysisPipelineSortingTests {

    private let duplicateSource = """
        func calculate() -> Int {
            let value = 42
            let result = value * 2
            let adjusted = result + 10
            let final = adjusted - 5
            return final
        }
        """

    private func makeTempDir(_ label: String) throws -> (URL, String) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pipeline_\(label)_\(UUID().uuidString)")
        let cacheDir = tempDir.appendingPathComponent(".swift-cpd-cache").path
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return (tempDir, cacheDir)
    }

    @Test("Given same type and file, when sorting, then orders by startLine")
    func sortingByStartLine() async throws {
        let (tempDir, cacheDir) = try makeTempDir("startline")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let twoFunctions = """
            func first() -> Int {
                let a = 1
                let b = 2
                let c = 3
                let d = 4
                return a + b + c + d
            }

            func second() -> Int {
                let a = 1
                let b = 2
                let c = 3
                let d = 4
                return a + b + c + d
            }
            """

        let fileA = tempDir.appendingPathComponent("Same.swift").path
        let fileB = tempDir.appendingPathComponent("Other.swift").path
        try twoFunctions.write(toFile: fileA, atomically: true, encoding: .utf8)
        try duplicateSource.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1, .type2]
        )
        let result = try await pipeline.analyze(files: [fileA, fileB])

        for index in 0 ..< result.cloneGroups.count - 1 {
            let current = result.cloneGroups[index]
            let next = result.cloneGroups[index + 1]
            guard
                let curFrag = current.fragments.first,
                let nextFrag = next.fragments.first
            else {
                continue
            }
            if current.type.rawValue == next.type.rawValue,
                curFrag.file == nextFrag.file
            {
                #expect(curFrag.startLine <= nextFrag.startLine)
            }
        }
    }

    @Test("Given same type but different files, when sorting, then orders by file")
    func sortingByFile() async throws {
        let (tempDir, cacheDir) = try makeTempDir("filesort")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("A.swift").path
        let fileB = tempDir.appendingPathComponent("B.swift").path
        let fileC = tempDir.appendingPathComponent("C.swift").path
        for path in [fileA, fileB, fileC] {
            try duplicateSource.write(toFile: path, atomically: true, encoding: .utf8)
        }

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1, .type2]
        )
        let result = try await pipeline.analyze(files: [fileC, fileA, fileB])

        for index in 0 ..< result.cloneGroups.count - 1 {
            let current = result.cloneGroups[index]
            let next = result.cloneGroups[index + 1]
            guard
                let curFrag = current.fragments.first,
                let nextFrag = next.fragments.first
            else {
                continue
            }
            if current.type.rawValue == next.type.rawValue {
                #expect(curFrag.file <= nextFrag.file)
            }
        }
    }

    @Test("Given equal types, when sorting, then falls through to file comparison")
    func sortingTypeEqualityFallsThrough() async throws {
        let (tempDir, cacheDir) = try makeTempDir("typeeq")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("A.swift").path
        let fileB = tempDir.appendingPathComponent("B.swift").path
        try duplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)
        try duplicateSource.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1]
        )
        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(!result.cloneGroups.isEmpty)
        #expect(result.cloneGroups.allSatisfy { $0.type == .type1 })

        for index in 0 ..< result.cloneGroups.count - 1 {
            let current = result.cloneGroups[index]
            let next = result.cloneGroups[index + 1]
            guard
                let curFrag = current.fragments.first,
                let nextFrag = next.fragments.first
            else {
                continue
            }
            if curFrag.file == nextFrag.file {
                #expect(curFrag.startLine <= nextFrag.startLine)
            } else {
                #expect(curFrag.file < nextFrag.file)
            }
        }
    }

    @Test("Given .swift file, when tokenizing, then uses SwiftTokenizer")
    func swiftFileUsesSwiftTokenizer() async throws {
        let (tempDir, cacheDir) = try makeTempDir("swifttok")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileA = tempDir.appendingPathComponent("A.swift").path
        try duplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1, cacheDirectory: cacheDir
        )
        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }

    @Test("Given .m file, when tokenizing, then uses CTokenizer")
    func mFileUsesCTokenizer() async throws {
        let (tempDir, cacheDir) = try makeTempDir("ctok")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let source = """
            int main() {
                int value = 42;
                return value;
            }
            """

        let fileA = tempDir.appendingPathComponent("A.m").path
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1, cacheDirectory: cacheDir
        )
        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }
}
