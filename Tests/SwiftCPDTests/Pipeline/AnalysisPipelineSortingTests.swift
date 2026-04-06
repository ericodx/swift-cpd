import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline Sorting")
struct AnalysisPipelineSortingTests {

    @Test("Given same type and file, when sorting, then orders by startLine")
    func sortingByStartLine() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_startline")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

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

        let fileA = tempDir + "/Same.swift"
        let fileB = tempDir + "/Other.swift"
        try twoFunctions.write(toFile: fileA, atomically: true, encoding: .utf8)
        try standardDuplicateSource.write(toFile: fileB, atomically: true, encoding: .utf8)

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
        let tempDir = createTempDirectory(prefix: "pipeline_filesort")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileA = tempDir + "/A.swift"
        let fileB = tempDir + "/B.swift"
        let fileC = tempDir + "/C.swift"
        for path in [fileA, fileB, fileC] {
            try standardDuplicateSource.write(toFile: path, atomically: true, encoding: .utf8)
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
        let tempDir = createTempDirectory(prefix: "pipeline_typeeq")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileA = tempDir + "/A.swift"
        let fileB = tempDir + "/B.swift"
        try standardDuplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)
        try standardDuplicateSource.write(toFile: fileB, atomically: true, encoding: .utf8)

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
        let tempDir = createTempDirectory(prefix: "pipeline_swifttok")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileA = tempDir + "/A.swift"
        try standardDuplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1, cacheDirectory: cacheDir
        )
        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }

    @Test("Given .m file, when tokenizing, then uses CTokenizer")
    func mFileUsesCTokenizer() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_ctok")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let source = """
            int main() {
                int value = 42;
                return value;
            }
            """

        let fileA = tempDir + "/A.m"
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1, cacheDirectory: cacheDir
        )
        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }
}
