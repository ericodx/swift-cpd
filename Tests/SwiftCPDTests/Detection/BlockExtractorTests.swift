import Testing

@testable import swift_cpd

@Suite("BlockExtractor")
struct BlockExtractorTests {

    private let extractor = BlockExtractor()
    private let tokenizer = SwiftTokenizer()

    private func extractBlocks(from source: String, file: String = "Test.swift") -> [CodeBlock] {
        let tokens = tokenizer.tokenize(source: source, file: file)
        return extractor.extract(source: source, file: file, tokens: tokens)
    }

    @Test("Given source with function, when extracting, then returns function body block")
    func functionBody() {
        let source = """
            func greet() {
                let name = "World"
                print(name)
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(!blocks.isEmpty)
        #expect(blocks[0].file == "Test.swift")
        #expect(blocks[0].startLine == 1)
        #expect(blocks[0].endLine == 4)
    }

    @Test("Given source with initializer, when extracting, then returns initializer body block")
    func initializerBody() {
        let source = """
            struct Foo {
                let value: Int
                init(value: Int) {
                    self.value = value
                }
            }
            """

        let blocks = extractBlocks(from: source)

        let initBlocks = blocks.filter { $0.startLine >= 3 }
        #expect(!initBlocks.isEmpty)
    }

    @Test("Given source with computed property, when extracting, then returns accessor block")
    func computedProperty() {
        let source = """
            struct Foo {
                var doubled: Int {
                    get {
                        return value * 2
                    }
                }
                let value: Int
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(!blocks.isEmpty)
    }

    @Test("Given source with closure, when extracting, then returns closure block")
    func closureBody() {
        let source = """
            let items = [1, 2, 3]
            let mapped = items.map { item in
                return item * 2
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(!blocks.isEmpty)
    }

    @Test("Given source with multiple functions, when extracting, then returns all blocks")
    func multipleFunctions() {
        let source = """
            func first() {
                let a = 1
                print(a)
            }

            func second() {
                let b = 2
                print(b)
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(blocks.count >= 2)
    }

    @Test("Given empty source, when extracting, then returns no blocks")
    func emptySource() {
        let blocks = extractBlocks(from: "")

        #expect(blocks.isEmpty)
    }

    @Test("Given source with nested function, when extracting, then returns both blocks")
    func nestedFunction() {
        let source = """
            func outer() {
                func inner() {
                    let x = 1
                    print(x)
                }
                inner()
            }
            """

        let blocks = extractBlocks(from: source)

        #expect(blocks.count >= 2)
    }

    @Test("Given function block, when extracting, then token indices map correctly")
    func tokenIndicesMapCorrectly() {
        let source = """
            func greet() {
                let name = "World"
                print(name)
            }
            """

        let tokens = tokenizer.tokenize(source: source, file: "Test.swift")
        let blocks = extractor.extract(source: source, file: "Test.swift", tokens: tokens)

        guard
            let block = blocks.first
        else {
            Issue.record("Expected at least one block")
            return
        }

        #expect(block.startTokenIndex >= 0)
        #expect(block.endTokenIndex < tokens.count)
        #expect(block.startTokenIndex <= block.endTokenIndex)
    }
}
