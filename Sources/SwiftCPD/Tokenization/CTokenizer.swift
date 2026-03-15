struct CTokenizer: Sendable {

    func tokenize(source: String, file: String) -> [Token] {
        var scanner = CTokenizerScanner(source: source, file: file)
        var tokens: [Token] = []

        while let token = scanner.nextToken() {
            tokens.append(token)
        }

        return tokens
    }
}
