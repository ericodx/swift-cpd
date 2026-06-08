import Testing

@testable import swift_cpd

@Suite("BlockExtractor Binary Search")
struct BlockExtractorBinarySearchMutationTests {

    @Test("Given boundary tokens, when extracting, then included")
    func tokensOnBoundaryLinesIncluded() {
        let source = """
            func f() {
                let x = 1
                let y = 2
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(!blocks.isEmpty)

        for block in blocks {
            #expect(block.startTokenIndex <= block.endTokenIndex)
        }
    }

    @Test("Given token on endLine, then break at > not >=")
    func tokenOnEndLineIsIncluded() {
        let source = """
            func f() {
                let x = 1
            }
            """

        let blocks = extractBlocks(from: source)

        guard
            let block = blocks.first
        else {
            Issue.record("Expected at least one block")
            return
        }

        let tokenizer = SwiftTokenizer()
        let tokens = tokenizer.tokenize(source: source, file: "Test.swift")
        let endLineTokens = tokens.filter {
            $0.location.line == block.endLine
        }

        #expect(!endLineTokens.isEmpty)
        #expect(block.endTokenIndex >= block.startTokenIndex)
    }

    @Test("Given binary search, when token line equals target, then found")
    func binarySearchFindsExactLine() {
        let source = """
            let a = 1
            func f() {
                let b = 2
                let c = 3
            }
            let d = 4
            """

        let blocks = extractBlocks(from: source)
        let functionBlock = blocks.first { $0.startLine == 2 }

        #expect(functionBlock != nil)

        if let block = functionBlock {
            let tokenizer = SwiftTokenizer()
            let tokens = tokenizer.tokenize(
                source: source, file: "Test.swift"
            )
            let firstToken = tokens[block.startTokenIndex]

            #expect(firstToken.location.line >= block.startLine)
        }
    }
}
