import Testing

@testable import swift_cpd

@Suite("UnifiedTokenMapper — MessageSend")
struct UnifiedTokenMapperMessageSendTests {

    let mapper = UnifiedTokenMapper()
    let location = SourceLocation(file: "test.m", line: 1, column: 1)

    @Test("Given exactly 4 tokens for message send, when mapping, then boundary guard passes and produces $ACCESS")
    func messageSendExactBoundaryProducesAccess() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "prop", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 1)
        #expect(result[0].text == "$ACCESS")
    }

    @Test("Given message send with colon, when mapping, then colons are filtered from output")
    func messageSendColonsFilteredFromOutput() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == ":" })
        #expect(result.contains { $0.text == "arg1" })
    }

    @Test("Given message send with colon, when mapping, then closing bracket is filtered from output")
    func messageSendClosingBracketFilteredFromOutput() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "]" })
    }

    @Test("Given message send with non-colon punctuation arg, when mapping, then non-colon punctuation is preserved")
    func messageSendNonColonPunctuationPreserved() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .punctuation, text: "+", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.contains { $0.text == "+" })
        #expect(!result.contains { $0.text == ":" })
        #expect(!result.contains { $0.text == "]" })
    }

    @Test("Given message send with colon, when mapping, then consumed count equals closing minus index plus one")
    func messageSendConsumedCountMatchesTokenSpan() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: ";", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 3)
        #expect(result[0].text == "$CALL")
        #expect(result[1].text == "arg")
        #expect(result[2].text == ";")
    }

    @Test(
        "Given message send with colon only inside nested brackets at depth 2, when mapping, then outer is not $CALL"
    )
    func nestedMessageSendInnerColonAtDepthTwoIgnored() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "outer", location: location),
            Token(kind: .identifier, text: "prop", location: location),
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "inner", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "val", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.contains { $0.text == "outer" })
        #expect(result.contains { $0.text == "prop" })
        #expect(result.contains { $0.text == "[" })
    }

    @Test("Given nested brackets with colon at depth 1, when mapping, then hasColon is true and produces $CALL")
    func nestedBracketsColonAtDepthOneProducesCall() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "inner", location: location),
            Token(kind: .identifier, text: "prop", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
    }
}
