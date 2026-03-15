@testable import swift_cpd

func makeSimpleTokens(_ texts: [String]) -> [Token] {
    texts.enumerated().map { index, text in
        Token(
            kind: .identifier,
            text: text,
            location: SourceLocation(file: "Test.swift", line: index + 1, column: 1)
        )
    }
}

func makeFileTokens(source: String, file: String) -> FileTokens {
    let tokenizer = SwiftTokenizer()
    let normalizer = TokenNormalizer()
    let tokens = tokenizer.tokenize(source: source, file: file)
    let normalized = normalizer.normalize(tokens)
    return FileTokens(file: file, source: source, tokens: tokens, normalizedTokens: normalized)
}

func makeTokens(
    _ specs: [(TokenKind, String)],
    file: String,
    startLine: Int = 1
) -> [Token] {
    specs.enumerated().map { index, spec in
        Token(
            kind: spec.0,
            text: spec.1,
            location: SourceLocation(file: file, line: startLine + index, column: 1)
        )
    }
}
