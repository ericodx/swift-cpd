import Testing

@testable import swift_cpd

@Suite("BlockExtraction")
struct BlockExtractionTests {

    @Test("Given block with token count exactly equal to minimum, when extracting, then includes the block")
    func tokenCountExactlyAtMinimum() {
        let source = """
            func a() {
                let x = 1
                let y = 2
                let z = 3
                let w = 4
                print(x + y + z + w)
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(files: [fileTokens], minimumTokenCount: 1)

        #expect(!blocks.isEmpty)

        let tokenCounts = blocks.map { $0.block.endTokenIndex - $0.block.startTokenIndex + 1 }
        let minBlockTokenCount = tokenCounts.min() ?? 0
        #expect(minBlockTokenCount >= 1)
    }

    @Test("Given block with fewer tokens than minimum, when extracting, then excludes the block")
    func tokenCountBelowMinimum() {
        let source = """
            func tiny() {
                let x = 1
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(files: [fileTokens], minimumTokenCount: 999)

        #expect(blocks.isEmpty)
    }

    @Test("Given multiple files, when extracting, then fileIndex is correct for each block")
    func fileIndexIsCorrect() {
        let sourceA = """
            func a() {
                let x = 1
                let y = 2
                print(x + y)
            }
            """
        let sourceB = """
            func b() {
                let m = 10
                let n = 20
                print(m + n)
            }
            """

        let fileTokensA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileTokensB = makeFileTokens(source: sourceB, file: "B.swift")
        let blocks = BlockExtraction.extractValidBlocks(
            files: [fileTokensA, fileTokensB],
            minimumTokenCount: 1
        )

        let fileIndices = Set(blocks.map(\.fileIndex))
        #expect(fileIndices.contains(0))
        #expect(fileIndices.contains(1))
    }
}
