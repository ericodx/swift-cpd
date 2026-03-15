struct TokenNormalizer: Sendable {

    func normalize(_ tokens: [Token]) -> [Token] {
        tokens.map { token in
            guard
                let placeholder = placeholder(for: token.kind)
            else {
                return token
            }

            return Token(
                kind: token.kind,
                text: placeholder,
                location: token.location
            )
        }
    }
}

extension TokenNormalizer {

    private func placeholder(for kind: TokenKind) -> String? {
        switch kind {
        case .identifier:
            return "$ID"

        case .typeName:
            return "$TYPE"

        case .integerLiteral, .floatingLiteral:
            return "$NUM"

        case .stringLiteral:
            return "$STR"

        case .keyword, .operatorToken, .punctuation:
            return nil
        }
    }
}
