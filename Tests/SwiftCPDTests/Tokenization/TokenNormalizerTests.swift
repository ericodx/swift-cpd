import Testing

@testable import swift_cpd

@Suite("TokenNormalizer")
struct TokenNormalizerTests {

    private let normalizer = TokenNormalizer()
    private let location = SourceLocation(file: "test.swift", line: 1, column: 1)

    @Test("Given identifier tokens, when normalizing, then replaces text with $ID")
    func normalizesIdentifiers() {
        let tokens = [
            Token(kind: .identifier, text: "myVariable", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "$ID")
        #expect(normalized[0].kind == .identifier)
    }

    @Test("Given type name tokens, when normalizing, then replaces text with $TYPE")
    func normalizesTypeNames() {
        let tokens = [
            Token(kind: .typeName, text: "String", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "$TYPE")
        #expect(normalized[0].kind == .typeName)
    }

    @Test("Given integer literal tokens, when normalizing, then replaces text with $NUM")
    func normalizesIntegerLiterals() {
        let tokens = [
            Token(kind: .integerLiteral, text: "42", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "$NUM")
    }

    @Test("Given float literal tokens, when normalizing, then replaces text with $NUM")
    func normalizesFloatLiterals() {
        let tokens = [
            Token(kind: .floatingLiteral, text: "3.14", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "$NUM")
    }

    @Test("Given string literal tokens, when normalizing, then replaces text with $STR")
    func normalizesStringLiterals() {
        let tokens = [
            Token(kind: .stringLiteral, text: "hello", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "$STR")
    }

    @Test("Given keyword tokens, when normalizing, then preserves original text")
    func preservesKeywords() {
        let tokens = [
            Token(kind: .keyword, text: "let", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "let")
    }

    @Test("Given operator tokens, when normalizing, then preserves original text")
    func preservesOperators() {
        let tokens = [
            Token(kind: .operatorToken, text: "=", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "=")
    }

    @Test("Given punctuation tokens, when normalizing, then preserves original text")
    func preservesPunctuation() {
        let tokens = [
            Token(kind: .punctuation, text: "(", location: location)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].text == "(")
    }

    @Test("Given mixed tokens, when normalizing, then preserves location on all tokens")
    func preservesLocations() {
        let specificLocation = SourceLocation(file: "main.swift", line: 5, column: 10)
        let tokens = [
            Token(kind: .identifier, text: "foo", location: specificLocation)
        ]

        let normalized = normalizer.normalize(tokens)

        #expect(normalized[0].location == specificLocation)
    }
}
