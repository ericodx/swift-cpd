import SwiftParser
import SwiftSyntax

struct SwiftTokenizer: Sendable {

    func tokenize(source: String, file: String) -> [Token] {
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: file, tree: sourceFile)
        var tokens: [Token] = []

        for syntaxToken in sourceFile.tokens(viewMode: .sourceAccurate) {
            guard
                let kind = mapTokenKind(syntaxToken)
            else {
                continue
            }

            let location = converter.location(for: syntaxToken.positionAfterSkippingLeadingTrivia)

            tokens.append(
                Token(
                    kind: kind,
                    text: syntaxToken.text,
                    location: SourceLocation(
                        file: file,
                        line: location.line,
                        column: location.column
                    )
                )
            )
        }

        return tokens
    }
}

extension SwiftTokenizer {

    private func mapTokenKind(_ syntaxToken: TokenSyntax) -> TokenKind? {
        switch syntaxToken.tokenKind {
        case .keyword:
            return .keyword

        case .identifier:
            return classifyIdentifier(syntaxToken)

        case .integerLiteral:
            return .integerLiteral

        case .floatLiteral:
            return .floatingLiteral

        case .stringSegment:
            return .stringLiteral

        case .binaryOperator, .prefixOperator, .postfixOperator, .equal, .arrow:
            return .operatorToken

        case .leftParen, .rightParen,
            .leftBrace, .rightBrace,
            .leftSquare, .rightSquare,
            .leftAngle, .rightAngle,
            .comma, .colon, .semicolon, .period,
            .exclamationMark, .postfixQuestionMark,
            .atSign, .pound, .backslash, .backtick,
            .ellipsis, .prefixAmpersand, .infixQuestionMark:
            return .punctuation

        case .poundAvailable, .poundUnavailable,
            .poundIf, .poundElse, .poundElseif, .poundEndif,
            .poundSourceLocation:
            return .keyword

        case .endOfFile, .stringQuote, .multilineStringQuote,
            .singleQuote, .rawStringPoundDelimiter,
            .regexLiteralPattern, .regexPoundDelimiter, .regexSlash,
            .dollarIdentifier, .wildcard, .shebang, .unknown:
            return nil
        }
    }

    private func classifyIdentifier(_ syntaxToken: TokenSyntax) -> TokenKind {
        let parent = syntaxToken.parent!

        if parent.is(IdentifierTypeSyntax.self) || parent.is(MemberTypeSyntax.self) {
            return .typeName
        }

        return .identifier
    }
}
