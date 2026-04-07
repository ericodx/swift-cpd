import Testing

@testable import swift_cpd

@Suite("CTokenizer Mutation Coverage")
struct CTokenizerMutationTests {

    let tokenizer = CTokenizer()

    @Test("Given line comment followed by code, when tokenizing, then code after newline is tokenized")
    func lineCommentSkipsToNewline() {
        let source = "// comment\nint x;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "x" })
    }

    @Test("Given block comment, when tokenizing, then initial advance past /* works correctly")
    func blockCommentInitialAdvance() {
        let source = "/* comment */ int y;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "y" })
        #expect(!tokens.contains { $0.text == "comment" })
    }

    @Test("Given block comment with no space after, when tokenizing, then next token parsed correctly")
    func blockCommentImmediatelyFollowedByCode() {
        let source = "/*x*/int z;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "z" })
    }

    @Test("Given block comment advance() calls removed, when tokenizing, then /* not skipped")
    func blockCommentAdvanceNotRemoved() {
        let source = "/**/int a;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "a" })
        #expect(!tokens.contains { $0.text == "*" })
        #expect(!tokens.contains { $0.text == "/" })
    }

    @Test("Given block comment with content, when first advance removed, then content leaks into tokens")
    func blockCommentFirstAdvanceRequired() {
        let source = "/* hello world */int b;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(!tokens.contains { $0.text == "hello" })
        #expect(!tokens.contains { $0.text == "world" })
    }

    @Test("Given preprocessor directive, when tokenizing, then directive is skipped")
    func preprocessorDirectiveSkipped() {
        let source = "#include <stdio.h>\nint main() {}"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "main" })
        #expect(!tokens.contains { $0.text == "#include" })
    }

    @Test("Given preprocessor at end of source, when < mutated to <=, then goes out of bounds")
    func preprocessorDirectiveBoundary() {
        let source = "#define FOO"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.isEmpty || !tokens.contains { $0.text == "#define" })
    }

    @Test("Given @interface keyword, when tokenizing, then scanned as keyword with letters and no digits needed")
    func atKeywordWithLettersOnly() {
        let source = "@interface MyClass"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.contains { $0.text == "@interface" && $0.kind == .keyword })
    }

    @Test("Given identifier with number like var1, when tokenizing, then scanned as single identifier")
    func identifierWithNumber() {
        let source = "int var1 = 5;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "var1" })
    }

    @Test("Given identifier with underscore like my_var, when tokenizing, then scanned as single identifier")
    func identifierWithUnderscore() {
        let source = "int my_var = 5;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "my_var" })
    }

    @Test("Given char literal with single char, when tokenizing, then parsed correctly")
    func charLiteralSingleChar() {
        let source = "char c = 'a';"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "a" && $0.kind == .integerLiteral })
    }

    @Test("Given char literal with escape sequence, when tokenizing, then parsed correctly")
    func charLiteralEscapeSequence() {
        let source = "char c = '\\n';"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let charTokens = tokens.filter { $0.kind == .integerLiteral }

        #expect(!charTokens.isEmpty)
    }

    @Test("Given char literal scanCharLiteral < boundary, when mutated to >, then escape breaks")
    func charLiteralBoundaryCheck() {
        let source = "char a = '\\t'; char b = 'x';"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let charTokens = tokens.filter { $0.kind == .integerLiteral }
        #expect(charTokens.count == 2)
    }

    @Test("Given number with exponent and sign, when tokenizing, then parses correctly")
    func numberWithExponentAndSign() {
        let source = "double x = 1.5e+10;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let floatTokens = tokens.filter { $0.kind == .floatingLiteral }

        #expect(!floatTokens.isEmpty)
        #expect(floatTokens.first?.text == "1.5e+10")
    }

    @Test("Given number with negative exponent, when tokenizing, then parses sign correctly")
    func numberWithNegativeExponent() {
        let source = "double x = 3.0e-5;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let floatTokens = tokens.filter { $0.kind == .floatingLiteral }

        #expect(!floatTokens.isEmpty)
        #expect(floatTokens.first?.text == "3.0e-5")
    }

    @Test("Given number with exponent but no sign, when tokenizing, then parses without sign")
    func numberWithExponentNoSign() {
        let source = "double x = 2.0e3;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let floatTokens = tokens.filter { $0.kind == .floatingLiteral }

        #expect(!floatTokens.isEmpty)
        #expect(floatTokens.first?.text == "2.0e3")
    }

    @Test("Given number at end of source with exponent sign check, when < mutated to <=, then boundary handled")
    func numberExponentSignBoundary() {
        let source = "1.5e"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(!tokens.isEmpty)
    }

    @Test("Given hex number, when tokenizing, then parsed as integer literal")
    func hexNumber() {
        let source = "int x = 0xFF;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "0xFF" && $0.kind == .integerLiteral })
    }

    @Test("Given @-prefixed non-keyword, when tokenizing, then @ is punctuation")
    func atNonKeywordIsPunctuation() {
        let source = "@123"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(tokens.first?.text == "@")
        #expect(tokens.first?.kind == .punctuation)
    }

    @Test("Given ObjC string literal @\"hello\", when tokenizing, then parsed as string literal")
    func objcStringLiteral() {
        let source = "@\"hello\""
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let stringTokens = tokens.filter { $0.kind == .stringLiteral }

        #expect(!stringTokens.isEmpty)
        #expect(stringTokens.first?.text == "hello")
    }

    @Test("Given string with escape, when tokenizing, then escape character handled")
    func stringWithEscape() {
        let source = "\"hello\\nworld\""
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        let stringTokens = tokens.filter { $0.kind == .stringLiteral }

        #expect(!stringTokens.isEmpty)
    }

    @Test("Given two-char operator, when tokenizing, then scanned as single operator")
    func twoCharOperator() {
        let source = "x == y"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "==" && $0.kind == .operatorToken })
    }

    @Test("Given line comment at end of file without newline, when tokenizing, then handles boundary")
    func lineCommentAtEndNoNewline() {
        let source = "int x; // end"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.contains { $0.text == "int" })
        #expect(tokens.contains { $0.text == "x" })
    }

    @Test("Given identifier starting with underscore, when tokenizing, then parsed correctly")
    func identifierStartingWithUnderscore() {
        let source = "_privateVar"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.count == 1)
        #expect(tokens[0].text == "_privateVar")
    }

    @Test("Given multiple line comments, when tokenizing, then all skipped correctly")
    func multipleLineComments() {
        let source = "// first\n// second\nint x;"
        let tokens = tokenizer.tokenize(source: source, file: "test.c")

        #expect(tokens.first?.text == "int")
    }

    @Test("Given @keyword with mixed chars, when || mutated to &&, then breaks")
    func atKeywordOrLogicForCharacterTypes() {
        let source = "@implementation_test MyClass"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        let atTokens = tokens.filter { $0.text.hasPrefix("@") }
        #expect(!atTokens.isEmpty)

        let source2 = "@property int x;"
        let tokens2 = tokenizer.tokenize(source: source2, file: "test.m")
        #expect(tokens2.contains { $0.text == "@property" && $0.kind == .keyword })
    }

    @Test("Given @keyword with digits like @property123, when scanning, then continues past digits")
    func atKeywordWithDigitsInBody() {
        let source = "@selector123 foo"
        let tokens = tokenizer.tokenize(source: source, file: "test.m")

        #expect(!tokens.isEmpty)
    }
}
