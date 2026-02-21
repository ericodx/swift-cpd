import Testing

@testable import swift_cpd

@Suite("UnifiedTokenMapper")
struct UnifiedTokenMapperTests {

    let mapper = UnifiedTokenMapper()
    let location = SourceLocation(file: "test.m", line: 1, column: 1)

    @Test("Given NSString token, when mapping, then returns String token")
    func nsStringMapping() {
        let tokens = [Token(kind: .typeName, text: "NSString", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "String")
        #expect(result[0].kind == .typeName)
    }

    @Test("Given NSInteger token, when mapping, then returns Int token")
    func nsIntegerMapping() {
        let tokens = [Token(kind: .typeName, text: "NSInteger", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "Int")
    }

    @Test("Given BOOL token, when mapping, then returns Bool token")
    func boolMapping() {
        let tokens = [Token(kind: .typeName, text: "BOOL", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "Bool")
    }

    @Test("Given id token, when mapping, then returns AnyObject token")
    func idMapping() {
        let tokens = [Token(kind: .typeName, text: "id", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "AnyObject")
    }

    @Test("Given YES keyword, when mapping, then returns true keyword")
    func yesMapping() {
        let tokens = [Token(kind: .keyword, text: "YES", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "true")
        #expect(result[0].kind == .keyword)
    }

    @Test("Given NO keyword, when mapping, then returns false keyword")
    func noMapping() {
        let tokens = [Token(kind: .keyword, text: "NO", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "false")
    }

    @Test("Given @interface keyword, when mapping, then returns class keyword")
    func interfaceMapping() {
        let tokens = [Token(kind: .keyword, text: "@interface", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "class")
    }

    @Test("Given @property keyword, when mapping, then returns var keyword")
    func propertyMapping() {
        let tokens = [Token(kind: .keyword, text: "@property", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "var")
    }

    @Test("Given regular identifier, when mapping, then preserves original text")
    func identifierUnchanged() {
        let tokens = [Token(kind: .identifier, text: "myVariable", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "myVariable")
        #expect(result[0].kind == .identifier)
    }

    @Test("Given unmapped keyword, when mapping, then preserves original text")
    func unmappedKeywordUnchanged() {
        let tokens = [Token(kind: .keyword, text: "if", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "if")
    }

    @Test("Given tokens, when mapping, then preserves location information")
    func preservesLocation() {
        let loc = SourceLocation(file: "File.m", line: 42, column: 10)
        let tokens = [Token(kind: .typeName, text: "NSString", location: loc)]
        let result = mapper.map(tokens)

        #expect(result[0].location == loc)
    }

    @Test("Given NSArray token, when mapping, then returns $COLLECTION_TYPE")
    func nsArrayCollectionType() {
        let tokens = [Token(kind: .typeName, text: "NSArray", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
        #expect(result[0].kind == .identifier)
    }

    @Test("Given NSMutableArray token, when mapping, then returns $COLLECTION_TYPE")
    func nsMutableArrayCollectionType() {
        let tokens = [Token(kind: .typeName, text: "NSMutableArray", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given NSDictionary token, when mapping, then returns $COLLECTION_TYPE")
    func nsDictionaryCollectionType() {
        let tokens = [Token(kind: .typeName, text: "NSDictionary", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given NSMutableDictionary token, when mapping, then returns $COLLECTION_TYPE")
    func nsMutableDictionaryCollectionType() {
        let tokens = [Token(kind: .typeName, text: "NSMutableDictionary", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given Array token, when mapping, then returns $COLLECTION_TYPE")
    func arrayCollectionType() {
        let tokens = [Token(kind: .typeName, text: "Array", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given Set token, when mapping, then returns $COLLECTION_TYPE")
    func setCollectionType() {
        let tokens = [Token(kind: .typeName, text: "Set", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given NSSet token, when mapping, then returns $COLLECTION_TYPE")
    func nsSetCollectionType() {
        let tokens = [Token(kind: .typeName, text: "NSSet", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given Dictionary token, when mapping, then returns $COLLECTION_TYPE")
    func dictionaryCollectionType() {
        let tokens = [Token(kind: .typeName, text: "Dictionary", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
    }

    @Test("Given ObjC message send with args, when mapping, then returns $CALL")
    func objcMessageSendWithArgs() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result[0].kind == .identifier)
        #expect(result.contains { $0.text == "arg" })
        #expect(!result.contains { $0.text == "[" })
        #expect(!result.contains { $0.text == "]" })
    }

    @Test("Given ObjC message send without args, when mapping, then returns $ACCESS")
    func objcMessageSendWithoutArgs() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "name", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 1)
        #expect(result[0].text == "$ACCESS")
        #expect(result[0].kind == .identifier)
    }

    @Test("Given Swift function call, when mapping, then returns $CALL")
    func swiftFunctionCall() {
        let tokens = [
            Token(kind: .identifier, text: "doSomething", location: location),
            Token(kind: .punctuation, text: "(", location: location),
            Token(kind: .identifier, text: "x", location: location),
            Token(kind: .punctuation, text: ")", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$CALL")
        #expect(result[1].text == "(")
        #expect(result[2].text == "x")
    }

    @Test("Given Swift property access, when mapping, then returns $ACCESS")
    func swiftPropertyAccess() {
        let tokens = [
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .punctuation, text: ".", location: location),
            Token(kind: .identifier, text: "name", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 1)
        #expect(result[0].text == "$ACCESS")
    }

    @Test("Given Swift method call with dot, when mapping, then does not produce $ACCESS")
    func swiftMethodCallNotAccess() {
        let tokens = [
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .punctuation, text: ".", location: location),
            Token(kind: .identifier, text: "doSomething", location: location),
            Token(kind: .punctuation, text: "(", location: location),
            Token(kind: .punctuation, text: ")", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "$ACCESS" })
    }

    @Test("Given unmapped typeName token, when mapping, then preserves original text and kind")
    func unmappedTypeNamePreserved() {
        let tokens = [Token(kind: .typeName, text: "CustomType", location: location)]
        let result = mapper.map(tokens)

        #expect(result[0].text == "CustomType")
        #expect(result[0].kind == .typeName)
    }

    @Test("Given nested ObjC message send, when mapping, then handles bracket depth")
    func nestedMessageSend() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "inner", location: location),
            Token(kind: .identifier, text: "value", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.contains { $0.text == "$CALL" })
    }

    @Test("Given ObjC message send with unclosed bracket, when mapping, then returns nil")
    func unclosedBracketMessageSend() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "arg", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "$CALL" })
    }

    @Test("Given bracket-identifier-identifier without closing bracket, when mapping, then no access token")
    func incompleteMessageSendNoAccess() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "prop", location: location),
            Token(kind: .punctuation, text: ";", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(!result.contains { $0.text == "$ACCESS" })
    }

    @Test("Given bracket without enough following tokens, when mapping, then falls through")
    func bracketWithInsufficientTokens() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "x", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.count == 2)
    }

    @Test("Given nested brackets in message send, when mapping, then handles depth correctly")
    func nestedBracketsInMessageSend() {
        let tokens = [
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "obj", location: location),
            Token(kind: .identifier, text: "method", location: location),
            Token(kind: .punctuation, text: "[", location: location),
            Token(kind: .identifier, text: "inner", location: location),
            Token(kind: .identifier, text: "msg", location: location),
            Token(kind: .punctuation, text: "]", location: location),
            Token(kind: .punctuation, text: ":", location: location),
            Token(kind: .identifier, text: "value", location: location),
            Token(kind: .punctuation, text: "]", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result.contains { $0.text == "$CALL" })
    }

    @Test("Given $COLLECTION_TYPE followed by paren, when mapping, then does not produce $CALL")
    func collectionTypeNotCall() {
        let tokens = [
            Token(kind: .typeName, text: "Array", location: location),
            Token(kind: .punctuation, text: "(", location: location),
            Token(kind: .punctuation, text: ")", location: location),
        ]

        let result = mapper.map(tokens)

        #expect(result[0].text == "$COLLECTION_TYPE")
        #expect(!result.contains { $0.text == "$CALL" })
    }
}
