import Testing

@testable import swift_cpd

@Suite("CTokenizer")
struct CTokenizerTests {

    let tokenizer = CTokenizer()

    @Test("Given C keywords, when tokenizing, then returns keyword tokens")
    func cKeywords() {
        let source = "if else for while return break"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 6)
        #expect(tokens.allSatisfy { $0.kind == .keyword })
        #expect(tokens[0].text == "if")
        #expect(tokens[5].text == "break")
    }

    @Test("Given Objective-C at-keywords, when tokenizing, then returns keyword tokens")
    func objcAtKeywords() {
        let source = "@interface @implementation @property @end"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 4)
        #expect(tokens.allSatisfy { $0.kind == .keyword })
        #expect(tokens[0].text == "@interface")
        #expect(tokens[3].text == "@end")
    }

    @Test("Given Objective-C value keywords, when tokenizing, then returns keyword tokens")
    func objcValueKeywords() {
        let source = "nil YES NO self super"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 5)
        #expect(tokens.allSatisfy { $0.kind == .keyword })
    }

    @Test("Given known type names, when tokenizing, then returns typeName tokens")
    func knownTypeNames() {
        let source = "NSArray NSString NSDictionary NSInteger BOOL id"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 6)
        #expect(tokens.allSatisfy { $0.kind == .typeName })
    }

    @Test("Given uppercase identifiers, when tokenizing, then returns typeName tokens")
    func uppercaseIdentifiersAsTypeNames() {
        let source = "MyClass CustomView"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 2)
        #expect(tokens.allSatisfy { $0.kind == .typeName })
    }

    @Test("Given lowercase identifiers, when tokenizing, then returns identifier tokens")
    func lowercaseIdentifiers() {
        let source = "count name result"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 3)
        #expect(tokens.allSatisfy { $0.kind == .identifier })
    }

    @Test("Given integer literals, when tokenizing, then returns integerLiteral tokens")
    func integerLiterals() {
        let source = "42 0xFF 0"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 3)
        #expect(tokens.allSatisfy { $0.kind == .integerLiteral })
        #expect(tokens[0].text == "42")
        #expect(tokens[1].text == "0xFF")
    }

    @Test("Given float literals, when tokenizing, then returns floatingLiteral tokens")
    func floatLiterals() {
        let source = "3.14 1.0e10"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 2)
        #expect(tokens.allSatisfy { $0.kind == .floatingLiteral })
        #expect(tokens[0].text == "3.14")
    }

    @Test("Given string literals, when tokenizing, then returns stringLiteral tokens")
    func stringLiterals() {
        let source = "\"hello\" @\"world\""
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 2)
        #expect(tokens.allSatisfy { $0.kind == .stringLiteral })
        #expect(tokens[0].text == "hello")
        #expect(tokens[1].text == "world")
    }

    @Test("Given operators, when tokenizing, then returns operatorToken tokens")
    func operators() {
        let source = "== != <= >= && || ->"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 7)
        #expect(tokens.allSatisfy { $0.kind == .operatorToken })
        #expect(tokens[0].text == "==")
        #expect(tokens[6].text == "->")
    }

    @Test("Given punctuation, when tokenizing, then returns punctuation tokens")
    func punctuation() {
        let source = "{ } ( ) [ ] ; , ."
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 9)
        #expect(tokens.allSatisfy { $0.kind == .punctuation })
    }

    @Test("Given line comments, when tokenizing, then skips them")
    func lineComments() {
        let source = "int x; // this is a comment\nint y;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let identifiers = tokens.filter { $0.kind == .identifier }
        #expect(identifiers.count == 2)
        #expect(identifiers[0].text == "x")
        #expect(identifiers[1].text == "y")
    }

    @Test("Given block comments, when tokenizing, then skips them")
    func blockComments() {
        let source = "int x; /* block comment */ int y;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let identifiers = tokens.filter { $0.kind == .identifier }
        #expect(identifiers.count == 2)
    }

    @Test("Given preprocessor directives, when tokenizing, then skips them")
    func preprocessorDirectives() {
        let source = "#import <Foundation/Foundation.h>\nint x;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.contains { $0.text == "x" })
        #expect(!tokens.contains { $0.text == "import" })
    }

    @Test("Given message send syntax, when tokenizing, then tokenizes bracket structure")
    func messageSendSyntax() {
        let source = "[obj method:arg]"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens[0].kind == .punctuation)
        #expect(tokens[0].text == "[")
        #expect(tokens[1].kind == .identifier)
        #expect(tokens[1].text == "obj")
        #expect(tokens[2].kind == .identifier)
        #expect(tokens[2].text == "method")
        #expect(tokens[3].kind == .punctuation)
        #expect(tokens[3].text == ":")
        #expect(tokens[4].kind == .identifier)
        #expect(tokens[4].text == "arg")
        #expect(tokens[5].kind == .punctuation)
        #expect(tokens[5].text == "]")
    }

    @Test("Given multiline source, when tokenizing, then tracks line and column")
    func lineAndColumnTracking() {
        let source = "int x;\nint y;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let xToken = tokens.first { $0.text == "x" }
        let yToken = tokens.first { $0.text == "y" }

        #expect(xToken?.location.line == 1)
        #expect(yToken?.location.line == 2)
    }

    @Test("Given char literal, when tokenizing, then returns integerLiteral token")
    func charLiteral() {
        let source = "'a'"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .integerLiteral)
        #expect(tokens[0].text == "a")
    }

    @Test("Given string with escape sequence, when tokenizing, then handles escape")
    func stringWithEscape() {
        let source = "\"hello\\nworld\""
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .stringLiteral)
    }

    @Test("Given char literal with escape, when tokenizing, then handles escape")
    func charLiteralWithEscape() {
        let source = "'\\n'"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .integerLiteral)
    }

    @Test("Given number with exponent and sign, when tokenizing, then returns single token")
    func numberWithExponentSign() {
        let source = "1e+5"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .floatingLiteral)
        #expect(tokens[0].text == "1e+5")
    }

    @Test("Given number with suffix, when tokenizing, then consumes suffix")
    func numberWithSuffix() {
        let source = "10UL"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .integerLiteral)
    }

    @Test("Given @ at end of input, when tokenizing, then returns punctuation")
    func atSignAtEnd() {
        let source = "@"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.count == 1)
        #expect(tokens[0].kind == .punctuation)
        #expect(tokens[0].text == "@")
    }

    @Test("Given @ followed by number, when tokenizing, then returns punctuation for @")
    func atSignFollowedByNonLetter() {
        let source = "@123"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens[0].kind == .punctuation)
        #expect(tokens[0].text == "@")
    }

    @Test("Given identical source twice, when tokenizing, then produces identical output")
    func determinism() {
        let source = "@interface MyClass : NSObject\n@property NSString *name;\n@end"
        let first = tokenizer.tokenize(source: source, file: "test.m")
        let second = tokenizer.tokenize(source: source, file: "test.m")

        #expect(first == second)
    }

    @Test("Given file name, when tokenizing, then tokens have correct file location")
    func fileLocation() {
        let source = "int x;"
        let tokens = tokenizer.tokenize(source: source, file: "MyFile.m")

        #expect(tokens.allSatisfy { $0.location.file == "MyFile.m" })
    }

    @Test("Given unknown character, when tokenizing, then skips and continues")
    func unknownCharacterSkipped() {
        let source = "int \u{01} x;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let texts = tokens.map(\.text)
        #expect(texts.contains("int"))
        #expect(texts.contains("x"))
    }

    @Test("Given unclosed block comment, when tokenizing, then handles gracefully")
    func unclosedBlockComment() {
        let source = "int x; /* unclosed comment"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let texts = tokens.map(\.text)
        #expect(texts.contains("int"))
        #expect(texts.contains("x"))
    }

    @Test("Given @ followed by unknown keyword, when tokenizing, then returns @ as punctuation")
    func atSignWithUnknownKeyword() {
        let source = "@customattr name;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let atTokens = tokens.filter { $0.text == "@" && $0.kind == .punctuation }
        #expect(!atTokens.isEmpty)
    }

    @Test("Given source with only block comment as slash, when tokenizing, then handles division vs comment")
    func slashNotFollowedByCommentMarker() {
        let source = "int x = 10 / 2;"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let texts = tokens.map(\.text)
        #expect(texts.contains("/"))
    }
}
