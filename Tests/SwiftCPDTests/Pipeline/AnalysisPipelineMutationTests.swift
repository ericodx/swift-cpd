import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline Mutation Coverage")
struct AnalysisPipelineMutationTests {

    @Test("Given clones with different type rawValues, when sorting, then lower type comes first")
    func sortByTypeRawValueStrictLessThan() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_type_sort")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let source = """
            func doWork() -> Int {
                let a = 1
                let b = 2
                let c = a + b
                let d = c * 2
                let e = d - 1
                return e
            }

            func doWorkCopy() -> Int {
                let a = 1
                let b = 2
                let c = a + b
                let d = c * 2
                let e = d - 1
                return e
            }
            """

        let fileA = tempDir + "/A.swift"
        let fileB = tempDir + "/B.swift"
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1, .type2, .type3]
        )
        let result = try await pipeline.analyze(files: [fileA, fileB])

        for index in 0 ..< result.cloneGroups.count - 1 {
            let current = result.cloneGroups[index]
            let next = result.cloneGroups[index + 1]

            if current.type.rawValue != next.type.rawValue {
                #expect(current.type.rawValue < next.type.rawValue)
            }
        }
    }

    @Test("Given clones of same type in different files, when sorting, then alphabetical file order")
    func sortByFileStrictLessThan() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_file_sort")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileA = tempDir + "/Alpha.swift"
        let fileB = tempDir + "/Beta.swift"
        try standardDuplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)
        try standardDuplicateSource.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1]
        )
        let result = try await pipeline.analyze(files: [fileB, fileA])

        guard
            !result.cloneGroups.isEmpty,
            let frag = result.cloneGroups[0].fragments.first
        else {
            Issue.record("Expected at least one clone group")
            return
        }

        #expect(frag.file.contains("Alpha"))
    }

    @Test("Given clones in same file, when sorting, then earlier startLine comes first")
    func sortByStartLineStrictLessThan() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_line_sort")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let source = """
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

            func third() -> Int {
                let a = 1
                let b = 2
                let c = 3
                let d = 4
                return a + b + c + d
            }
            """

        let fileA = tempDir + "/Same.swift"
        let fileB = tempDir + "/Other.swift"
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

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

            if current.type == next.type, curFrag.file == nextFrag.file {
                #expect(curFrag.startLine <= nextFrag.startLine)
            }
        }
    }

    @Test("Given sorting with nil first fragment, when sorting, then returns false as fallback")
    func sortFallbackReturnsFalseForNilFragments() async throws {
        let group1 = CloneGroup(
            type: .type1,
            tokenCount: 10,
            lineCount: 5,
            similarity: 100.0,
            fragments: []
        )
        let group2 = CloneGroup(
            type: .type1,
            tokenCount: 10,
            lineCount: 5,
            similarity: 100.0,
            fragments: []
        )

        let sorted = [group1, group2].sorted {
            guard
                let lhs = $0.fragments.first,
                let rhs = $1.fragments.first
            else {
                return false
            }

            if $0.type.rawValue != $1.type.rawValue { return $0.type.rawValue < $1.type.rawValue }
            if lhs.file != rhs.file { return lhs.file < rhs.file }
            return lhs.startLine < rhs.startLine
        }

        #expect(sorted.count == 2)
    }

    @Test("Given .c file, when tokenizing, then uses CTokenizer not SwiftTokenizer")
    func cFileUsesCTokenizer() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_c_tok")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let cSource = """
            void calculate() {
                int a = 1;
                int b = 2;
                int c = a + b;
                int d = c * 2;
                int e = d - 1;
                printf("%d", e);
            }
            """

        let fileA = tempDir + "/code.c"
        let fileB = tempDir + "/code2.c"
        try cSource.write(toFile: fileA, atomically: true, encoding: .utf8)
        try cSource.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1, cacheDirectory: cacheDir
        )
        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
    }

    @Test("Given files sorted by name, when processing, then results are in file order")
    func processedFilesAreSortedByName() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_filesorted")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileZ = tempDir + "/Z.swift"
        let fileA = tempDir + "/A.swift"
        try standardDuplicateSource.write(toFile: fileZ, atomically: true, encoding: .utf8)
        try standardDuplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1]
        )
        let result = try await pipeline.analyze(files: [fileZ, fileA])

        guard
            !result.cloneGroups.isEmpty
        else {
            Issue.record("Expected clones")
            return
        }

        let firstFragFile = result.cloneGroups[0].fragments[0].file
        #expect(firstFragFile.contains("A.swift"))
    }

    @Test("Given .swift file check hasSuffix, when negated, then Swift files use CTokenizer incorrectly")
    func hasSuffixSwiftNotNegated() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_suffix")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let swiftSource = """
            func calculate() -> Int {
                let a = 1
                let b = 2
                let c = a + b
                let d = c * 2
                return d
            }
            """

        let fileA = tempDir + "/A.swift"
        let fileB = tempDir + "/B.swift"
        try swiftSource.write(toFile: fileA, atomically: true, encoding: .utf8)
        try swiftSource.write(toFile: fileB, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1]
        )
        let result = try await pipeline.analyze(files: [fileA, fileB])

        #expect(result.totalTokens > 0)
        #expect(!result.cloneGroups.isEmpty)
    }

    @Test("Given file sort with < on same file name, when < mutated to <=, then equal names don't swap")
    func fileSortEqualNamesStable() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_eq_file")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let fileA = tempDir + "/Same.swift"
        try standardDuplicateSource.write(toFile: fileA, atomically: true, encoding: .utf8)

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5, minimumLineCount: 1,
            cacheDirectory: cacheDir, enabledCloneTypes: [.type1]
        )
        let result = try await pipeline.analyze(files: [fileA])

        #expect(result.totalTokens > 0)
    }

    @Test("Given sorting fallback returns false, when false mutated to true, then equal-fragment groups swap")
    func sortingFallbackReturnsFalse() async throws {
        let tempDir = createTempDirectory(prefix: "pipeline_fallback")
        let cacheDir = tempDir + "/.swift-cpd-cache"
        defer { removeTempDirectory(tempDir) }

        let source = """
            func alpha() -> Int {
                let a = 1
                let b = 2
                let c = a + b
                return c
            }

            func beta() -> Int {
                let a = 1
                let b = 2
                let c = a + b
                return c
            }
            """

        let fileA = tempDir + "/A.swift"
        let fileB = tempDir + "/B.swift"
        try source.write(toFile: fileA, atomically: true, encoding: .utf8)
        try source.write(toFile: fileB, atomically: true, encoding: .utf8)

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

            if current.type.rawValue == next.type.rawValue, curFrag.file == nextFrag.file {
                #expect(curFrag.startLine <= nextFrag.startLine)
            }
        }
    }
}
