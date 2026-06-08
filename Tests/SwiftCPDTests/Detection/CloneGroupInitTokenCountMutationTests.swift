import Testing

@testable import swift_cpd

@Suite("CloneGroup Init Token Count")
struct CloneGroupInitTokenCountMutationTests {

    @Test("Given pair, when creating CloneGroup, then lineCount correct")
    func lineCountUsesCorrectFormula() {
        let source = """
            func f() {
                let a = 1
                let b = 2
                let c = 3
                print(a + b + c)
            }
            func g() {
                let x = 1
                let y = 2
                let z = 3
                print(x + y + z)
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        guard
            blocks.count >= 2
        else {
            Issue.record("Expected at least two blocks")
            return
        }

        let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
        let group = CloneGroup(
            type: .type1, pair: pair, files: [fileTokens],
            similarity: 1.0, minimumLineCount: 1
        )

        #expect(group != nil)

        if let group = group {
            let lineCountA =
                blocks[0].block.endLine - blocks[0].block.startLine + 1
            let lineCountB =
                blocks[1].block.endLine - blocks[1].block.startLine + 1
            let expectedLineCount = max(lineCountA, lineCountB)

            #expect(group.lineCount == expectedLineCount)

            let tokenCountA =
                blocks[0].block.endTokenIndex
                - blocks[0].block.startTokenIndex + 1
            let tokenCountB =
                blocks[1].block.endTokenIndex
                - blocks[1].block.startTokenIndex + 1
            let expectedTokenCount = max(tokenCountA, tokenCountB)

            #expect(group.tokenCount == expectedTokenCount)
        }
    }

    @Test("Given lineCount below minimum, then returns nil")
    func lineCountBelowMinimumReturnsNil() {
        let source = """
            func f() { let a = 1 }
            func g() { let x = 1 }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        guard
            blocks.count >= 2
        else {
            Issue.record("Expected at least two blocks")
            return
        }

        let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
        let group = CloneGroup(
            type: .type1, pair: pair, files: [fileTokens],
            similarity: 1.0, minimumLineCount: 999
        )

        #expect(group == nil)
    }

    @Test("Given lineCount + 1, when + mutated to -, then wrong")
    func cloneGroupLineCountArithmeticExact() {
        let source = """
            func f() {
                let a = 1
                let b = 2
                let c = 3
            }
            func g() {
                let x = 1
                let y = 2
                let z = 3
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        guard blocks.count >= 2 else {
            Issue.record("Expected at least two blocks")
            return
        }

        let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
        let group = CloneGroup(
            type: .type1, pair: pair, files: [fileTokens],
            similarity: 1.0, minimumLineCount: 1
        )

        guard let group = group else {
            Issue.record("Expected a clone group")
            return
        }

        let lineA =
            blocks[0].block.endLine - blocks[0].block.startLine + 1
        let lineB =
            blocks[1].block.endLine - blocks[1].block.startLine + 1
        #expect(group.lineCount == max(lineA, lineB))
        #expect(group.lineCount >= 2)
    }

    @Test("Given tokenCount - 1, when - mutated to +, then wrong")
    func cloneGroupTokenCountArithmeticExact() {
        let source = """
            func f() {
                let a = 1
                let b = 2
            }
            func g() {
                let x = 1
                let y = 2
            }
            """

        let fileTokens = makeFileTokens(source: source, file: "Test.swift")
        let blocks = BlockExtraction.extractValidBlocks(
            files: [fileTokens], minimumTokenCount: 1
        )

        guard blocks.count >= 2 else {
            Issue.record("Expected at least two blocks")
            return
        }

        let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
        let group = CloneGroup(
            type: .type1, pair: pair, files: [fileTokens],
            similarity: 1.0, minimumLineCount: 1
        )

        guard let group = group else {
            Issue.record("Expected a clone group")
            return
        }

        let tokA =
            blocks[0].block.endTokenIndex
            - blocks[0].block.startTokenIndex + 1
        let tokB =
            blocks[1].block.endTokenIndex
            - blocks[1].block.startTokenIndex + 1
        #expect(group.tokenCount == max(tokA, tokB))
        #expect(group.tokenCount > 2)
    }
}
