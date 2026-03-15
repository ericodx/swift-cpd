import Testing

@testable import swift_cpd

@Suite("SwiftTokenizer")
struct SwiftTokenizerTests {

    private let tokenizer = SwiftTokenizer()

    @Test("Given a simple declaration, when tokenizing, then returns correct token kinds")
    func simpleDeclaration() {
        let source = "let x: Int = 42"
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        #expect(tokens.count == 6)
        #expect(
            tokens[0]
                == Token(kind: .keyword, text: "let", location: SourceLocation(file: "test.swift", line: 1, column: 1)))
        #expect(
            tokens[1]
                == Token(kind: .identifier, text: "x", location: SourceLocation(file: "test.swift", line: 1, column: 5))
        )
        #expect(
            tokens[2]
                == Token(
                    kind: .punctuation, text: ":", location: SourceLocation(file: "test.swift", line: 1, column: 6)))
        #expect(
            tokens[3]
                == Token(kind: .typeName, text: "Int", location: SourceLocation(file: "test.swift", line: 1, column: 8))
        )
        #expect(
            tokens[4]
                == Token(
                    kind: .operatorToken, text: "=", location: SourceLocation(file: "test.swift", line: 1, column: 12)))
        #expect(
            tokens[5]
                == Token(
                    kind: .integerLiteral, text: "42", location: SourceLocation(file: "test.swift", line: 1, column: 14)
                ))
    }

    @Test("Given source with comments, when tokenizing, then strips comments")
    func stripsComments() {
        let source = """
            // this is a comment
            let x = 1
            /* block comment */
            let y = 2
            """
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")
        let texts = tokens.map(\.text)

        #expect(!texts.contains("// this is a comment"))
        #expect(!texts.contains("/* block comment */"))
        #expect(texts.contains("x"))
        #expect(texts.contains("y"))
    }

    @Test("Given source with whitespace, when tokenizing, then strips whitespace")
    func stripsWhitespace() {
        let source = "let    x   =   1"
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        #expect(tokens.count == 4)
        #expect(tokens[0].text == "let")
        #expect(tokens[1].text == "x")
        #expect(tokens[2].text == "=")
        #expect(tokens[3].text == "1")
    }

    @Test("Given multiline source, when tokenizing, then tracks line and column accurately")
    func lineColumnAccuracy() {
        let source = """
            let x = 1
            var y = 2
            """
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        let letToken = tokens[0]
        #expect(letToken.location.line == 1)
        #expect(letToken.location.column == 1)

        let varToken = tokens[4]
        #expect(varToken.location.line == 2)
        #expect(varToken.location.column == 1)
    }

    @Test("Given type annotations, when tokenizing, then classifies type names correctly")
    func typeNameClassification() {
        let source = "func greet(name: String) -> Bool { return true }"
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        let stringToken = tokens.first { $0.text == "String" }
        #expect(stringToken?.kind == .typeName)

        let boolToken = tokens.first { $0.text == "Bool" }
        #expect(boolToken?.kind == .typeName)

        let nameToken = tokens.first { $0.text == "name" }
        #expect(nameToken?.kind == .identifier)
    }

    @Test("Given identical source, when tokenizing twice, then produces identical output")
    func determinism() {
        let source = "struct Foo { var bar: Int = 0 }"
        let firstRun = tokenizer.tokenize(source: source, file: "test.swift")
        let secondRun = tokenizer.tokenize(source: source, file: "test.swift")

        #expect(firstRun == secondRun)
    }

    @Test("Given float literal, when tokenizing, then returns floatingLiteral kind")
    func floatLiteral() {
        let source = "let pi = 3.14"
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        let piToken = tokens.first { $0.text == "3.14" }
        #expect(piToken?.kind == .floatingLiteral)
    }

    @Test("Given source with compiler directives, when tokenizing, then returns keyword tokens")
    func compilerDirectives() {
        let source = """
            #if DEBUG
            let x = 1
            #else
            let x = 2
            #endif
            """
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        let directives = tokens.filter { ["#if", "#else", "#endif"].contains($0.text) }
        #expect(directives.count == 3)
        #expect(directives.allSatisfy { $0.kind == .keyword })
    }

    @Test("Given string literal, when tokenizing, then returns stringLiteral kind")
    func stringLiteral() {
        let source = """
            let greeting = "hello"
            """
        let tokens = tokenizer.tokenize(source: source, file: "test.swift")

        let helloToken = tokens.first { $0.text == "hello" }
        #expect(helloToken?.kind == .stringLiteral)
    }
}
