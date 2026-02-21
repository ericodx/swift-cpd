enum TokenKind: String, Sendable, Equatable, Hashable, Codable {

    case keyword
    case identifier
    case typeName
    case integerLiteral
    case floatingLiteral
    case stringLiteral
    case operatorToken
    case punctuation
}
