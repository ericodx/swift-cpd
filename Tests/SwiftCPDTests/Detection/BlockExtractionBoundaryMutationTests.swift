import Testing

@testable import swift_cpd

@Suite("BlockExtraction Boundary")
struct BlockExtractionBoundaryMutationTests {

    @Test("Given block at minimum, when extracting, then block is included")
    func blockExactlyAtMinimum() {
        let source = """
            func f() {
                let a = 1
                let b = 2
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let allBlocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        let blockCounts = allBlocks.map {
            $0.block.endTokenIndex - $0.block.startTokenIndex + 1
        }

        for count in blockCounts {
            #expect(count >= 1)
        }

        #expect(!allBlocks.isEmpty)
    }

    @Test("Given block below minimum, when extracting, then excluded")
    func blockOneBelowMinimum() {
        let source = """
            func f() {
                let a = 1
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let allBlocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        let maxCount =
            allBlocks.map {
                $0.block.endTokenIndex - $0.block.startTokenIndex + 1
            }.max() ?? 0

        let excludedBlocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: maxCount + 1
        )

        #expect(excludedBlocks.isEmpty)
    }

    @Test("Given endTokenIndex - startTokenIndex + 1, when + mutated to -, then wrong")
    func tokenCountArithmeticPlusOne() {
        let source = """
            func f() {
                let a = 1
                let b = 2
                let c = 3
                print(a + b + c)
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let allBlocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        guard
            let block = allBlocks.first
        else {
            Issue.record("Expected at least one block")
            return
        }

        let tokenCount =
            block.block.endTokenIndex - block.block.startTokenIndex + 1
        #expect(tokenCount > 0)

        let blocksAtExact = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: tokenCount
        )
        let blocksAboveExact = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: tokenCount + 1
        )

        #expect(blocksAtExact.count > blocksAboveExact.count)
    }
}
