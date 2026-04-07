import Testing

@testable import swift_cpd

@Suite("UnifiedTokenMapper Mutation Coverage")
struct UnifiedTokenMapperMutationTests {

    let mapper = UnifiedTokenMapper()
    let location = SourceLocation(file: "test.m", line: 1, column: 1)

    @Test("Given message send with exactly 4 tokens, when mapping, then boundary guard works correctly")
    func messageSendBoundaryExactlyFourTokens() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "name", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 1)
        #expect(result[0].text == "$ACCESS")
    }

    @Test("Given message send with colon argument, when mapping, then closing bracket not included in result")
    func messageSendClosingBracketExcluded() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "setVal", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result.contains { $0.text == "arg1" })
        #expect(!result.contains { $0.text == ":" })
        #expect(!result.contains { $0.text == "]" })
    }

    @Test("Given message send with multiple arguments, when mapping, then colons are excluded but values kept")
    func messageSendColonsExcludedValuesKept() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "val1", location: location),
            Token(kind: .identifier, text: "key2", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "val2", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result.contains { $0.text == "val1" })
        #expect(result.contains { $0.text == "val2" })
        #expect(result.contains { $0.text == "key2" })
        let colonCount = result.filter { $0.text == ":" }.count
        #expect(colonCount == 0)
    }

    @Test("Given no-arg message send at index+3 boundary, then guard works")
    func messageSendWithoutArgsSecondGuardBoundary() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "self", location: location),
            Token(kind: .identifier, text: "count", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: ";", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$ACCESS")
        #expect(result[1].text == ";")
    }

    @Test("Given bracket-identifier-identifier-non-bracket at exact boundary, when mapping, then falls through")
    func messageSendSecondGuardFailsCorrectly() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "prop", location: location),
            Token(kind: .identifier, text: "extra", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "$ACCESS" })
        #expect(!result.contains { $0.text == "$CALL" })
    }

    @Test("Given scan with depth reaching zero, when scanning, then returns correct closing index")
    func scanBracketedRegionDepthReachesZero() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 2)
        #expect(result[0].text == "$CALL")
        #expect(result[1].text == "arg")
    }

    @Test("Given argument loop at closing bracket, then stops before it")
    func argumentLoopStopsBeforeClosing() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "doWork", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .integerLiteral, text: "42", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result[1].text == "42")
        #expect(result.count == 2)
    }

    @Test("Given message send with bracket argument, when mapping, then consumed count is correct")
    func messageSendConsumedCountCorrect() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "msg", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "val", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: ";", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result.last?.text == ";")
    }

    @Test("Given index + 3 < tokens.count, when < mutated to <=, then boundary at exactly count fails")
    func messageSendFirstGuardBoundary() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "name", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "$ACCESS" })
        #expect(!result.contains { $0.text == "$CALL" })
        #expect(result.count == 3)
    }

    @Test("Given argument loop while argumentIndex < closing, when < mutated to <=, then closing bracket included")
    func argumentLoopBoundary() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .identifier, text: "key2", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg2", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "]" })
        #expect(result[0].text == "$CALL")
    }

    @Test("Given token.kind != .punctuation check, when != mutated to ==, then non-punctuation tokens excluded")
    func tokenKindNotEqualCheck() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.contains { $0.text == "arg1" })
    }

    @Test("Given closing - index + 1 for consumed count, when + mutated to -, then consumed is wrong")
    func consumedCountArithmetic() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg1", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .identifier, text: "afterToken", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result.last?.text == "afterToken")
        #expect(result.count == 3)
    }

    @Test("Given scanBracketedRegion depth > 0, when > mutated to >=, then early exit at depth 0")
    func scanBracketedRegionDepthBoundary() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "inner", location: location),
            Token(kind: .identifier, text: "msg", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
    }

    @Test("Given second guard index+3 < count, when < to <=, then fails")
    func messageSendSecondGuardBoundary() {
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
}
