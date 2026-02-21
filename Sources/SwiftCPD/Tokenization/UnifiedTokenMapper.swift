struct UnifiedTokenMapper: Sendable {

    func map(_ tokens: [Token]) -> [Token] {
        let typeMapped = tokens.map(mapToken)
        return normalizePatterns(typeMapped)
    }
}

extension UnifiedTokenMapper {

    private func mapToken(_ token: Token) -> Token {
        guard
            let mapped = mapping(for: token)
        else {
            return token
        }

        return Token(
            kind: mapped.kind,
            text: mapped.text,
            location: token.location
        )
    }

    private func mapping(for token: Token) -> (kind: TokenKind, text: String)? {
        switch token.kind {
        case .typeName:
            if collectionTypes.contains(token.text) {
                return (.identifier, "$COLLECTION_TYPE")
            }

            if let text = typeMappings[token.text] {
                return (.typeName, text)
            }

            return nil

        case .keyword:
            if let text = keywordMappings[token.text] {
                return (.keyword, text)
            }

            return nil

        default:
            return nil
        }
    }

    private var collectionTypes: Set<String> {
        [
            "Array", "NSArray", "NSMutableArray",
            "Dictionary", "NSDictionary", "NSMutableDictionary",
            "Set", "NSSet", "NSMutableSet",
            "NSOrderedSet", "NSMutableOrderedSet",
        ]
    }

    private var typeMappings: [String: String] {
        [
            "NSString": "String",
            "NSMutableString": "String",
            "NSInteger": "Int",
            "NSUInteger": "Int",
            "CGFloat": "Int",
            "NSObject": "AnyObject",
            "BOOL": "Bool",
            "id": "AnyObject",
        ]
    }

    private var keywordMappings: [String: String] {
        [
            "YES": "true",
            "NO": "false",
            "@interface": "class",
            "@implementation": "class",
            "@property": "var",
        ]
    }
}

extension UnifiedTokenMapper {

    private func normalizePatterns(_ tokens: [Token]) -> [Token] {
        var result: [Token] = []
        var index = 0

        while index < tokens.count {
            if let consumed = tryMessageSend(tokens, at: index, into: &result) {
                index += consumed
                continue
            }

            if let consumed = tryFunctionCall(tokens, at: index, into: &result) {
                index += consumed
                continue
            }

            if let consumed = tryPropertyAccess(tokens, at: index, into: &result) {
                index += consumed
                continue
            }

            result.append(tokens[index])
            index += 1
        }

        return result
    }

    private func tryMessageSend(
        _ tokens: [Token],
        at index: Int,
        into result: inout [Token]
    ) -> Int? {
        guard
            index + 3 < tokens.count,
            tokens[index].kind == .punctuation,
            tokens[index].text == "[",
            tokens[index + 1].kind == .identifier,
            tokens[index + 2].kind == .identifier
        else {
            return nil
        }

        let location = tokens[index].location

        let scan = scanBracketedRegion(tokens, from: index + 3)

        if scan.hasColon {
            guard
                let closing = scan.closingIndex
            else {
                return nil
            }

            result.append(Token(kind: .identifier, text: "$CALL", location: location))

            var argumentIndex = index + 3

            while argumentIndex < closing {
                let token = tokens[argumentIndex]

                if (token.kind != .punctuation || token.text != ":")
                    && (token.kind != .punctuation || token.text != "]")
                {
                    result.append(token)
                }

                argumentIndex += 1
            }

            return closing - index + 1
        }

        guard
            index + 3 < tokens.count,
            tokens[index + 3].kind == .punctuation,
            tokens[index + 3].text == "]"
        else {
            return nil
        }

        result.append(Token(kind: .identifier, text: "$ACCESS", location: location))
        return 4
    }

    private func scanBracketedRegion(
        _ tokens: [Token],
        from start: Int
    ) -> (hasColon: Bool, closingIndex: Int?) {
        var depth = 1
        var index = start
        var foundColon = false

        while index < tokens.count && depth > 0 {
            let token = tokens[index]

            if token.kind == .punctuation && token.text == "[" {
                depth += 1
            } else if token.kind == .punctuation && token.text == "]" {
                depth -= 1

                if depth == 0 {
                    return (foundColon, index)
                }
            } else if depth == 1 && token.kind == .punctuation && token.text == ":" {
                foundColon = true
            }

            index += 1
        }

        return (foundColon, nil)
    }

    private func tryFunctionCall(
        _ tokens: [Token],
        at index: Int,
        into result: inout [Token]
    ) -> Int? {
        guard
            index + 1 < tokens.count,
            tokens[index].kind == .identifier,
            tokens[index].text != "$COLLECTION_TYPE",
            tokens[index + 1].kind == .punctuation,
            tokens[index + 1].text == "("
        else {
            return nil
        }

        result.append(Token(kind: .identifier, text: "$CALL", location: tokens[index].location))
        result.append(tokens[index + 1])
        return 2
    }

    private func tryPropertyAccess(
        _ tokens: [Token],
        at index: Int,
        into result: inout [Token]
    ) -> Int? {
        guard
            index + 2 < tokens.count,
            tokens[index].kind == .identifier,
            tokens[index + 1].kind == .punctuation,
            tokens[index + 1].text == ".",
            tokens[index + 2].kind == .identifier
        else {
            return nil
        }

        let isFollowedByParen =
            index + 3 < tokens.count
            && tokens[index + 3].kind == .punctuation
            && tokens[index + 3].text == "("

        if isFollowedByParen {
            return nil
        }

        result.append(Token(kind: .identifier, text: "$ACCESS", location: tokens[index].location))
        return 3
    }
}
