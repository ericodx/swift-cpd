struct CTokenizerScanner {

    init(source: String, file: String) {
        self.source = source
        self.file = file
        self.index = source.startIndex
    }
    let source: String
    let file: String
    var index: String.Index
    var line: Int = 1
    var column: Int = 1

    mutating func nextToken() -> Token? {
        skipWhitespaceAndComments()

        guard
            index < source.endIndex
        else {
            return nil
        }

        let char = source[index]

        if char == "#" {
            skipPreprocessorDirective()
            return nextToken()
        }

        if char == "@" {
            return scanAtKeywordOrString()
        }

        if char == "\"" {
            return scanString()
        }

        if char == "'" {
            return scanCharLiteral()
        }

        if char.isLetter || char == "_" {
            return scanIdentifierOrKeyword()
        }

        if char.isNumber {
            return scanNumber()
        }

        if CLanguageVocabulary.operatorStartCharacters.contains(char) {
            return scanOperator()
        }

        if CLanguageVocabulary.punctuationCharacters.contains(char) {
            return scanPunctuation()
        }

        advance()
        return nextToken()
    }

    mutating func advance() {
        if source[index] == "\n" {
            line += 1
            column = 1
        } else {
            column += 1
        }

        index = source.index(after: index)
    }

    func peek(offset: Int) -> Character? {
        var current = index

        for _ in 0 ..< offset {
            current = source.index(after: current)
        }

        guard
            current < source.endIndex
        else {
            return nil
        }

        return source[current]
    }

    func makeToken(_ kind: TokenKind, _ text: String, _ line: Int, _ column: Int) -> Token {
        Token(
            kind: kind,
            text: text,
            location: SourceLocation(file: file, line: line, column: column)
        )
    }
}

extension CTokenizerScanner {

    mutating func skipWhitespaceAndComments() {
        while index < source.endIndex {
            let char = source[index]

            if char.isWhitespace {
                advance()
                continue
            }

            if char == "/" {
                let next = peek(offset: 1)

                if next == "/" {
                    skipLineComment()
                    continue
                }

                if next == "*" {
                    skipBlockComment()
                    continue
                }
            }

            break
        }
    }

    mutating func skipLineComment() {
        while index < source.endIndex, source[index] != "\n" {
            advance()
        }
    }

    mutating func skipBlockComment() {
        advance()
        advance()

        while index < source.endIndex {
            if source[index] == "*", peek(offset: 1) == "/" {
                advance()
                advance()
                return
            }

            advance()
        }
    }

    mutating func skipPreprocessorDirective() {
        while index < source.endIndex, source[index] != "\n" {
            advance()
        }
    }
}

extension CTokenizerScanner {

    mutating func scanAtKeywordOrString() -> Token {
        let startLine = line
        let startColumn = column

        advance()

        guard
            index < source.endIndex
        else {
            return makeToken(.punctuation, "@", startLine, startColumn)
        }

        if source[index] == "\"" {
            return scanString(startLine: startLine, startColumn: startColumn)
        }

        guard
            source[index].isLetter
        else {
            return makeToken(.punctuation, "@", startLine, startColumn)
        }

        var text = "@"

        while index < source.endIndex, source[index].isLetter || source[index].isNumber || source[index] == "_" {
            text.append(source[index])
            advance()
        }

        if CLanguageVocabulary.objcAtKeywords.contains(text) {
            return makeToken(.keyword, text, startLine, startColumn)
        }

        return makeToken(.punctuation, "@", startLine, startColumn)
    }

    mutating func scanString(startLine: Int? = nil, startColumn: Int? = nil) -> Token {
        let sLine = startLine ?? line
        let sColumn = startColumn ?? column

        advance()

        var text = ""

        while index < source.endIndex, source[index] != "\"" {
            if source[index] == "\\" {
                advance()

                if index < source.endIndex {
                    advance()
                }

                continue
            }

            text.append(source[index])
            advance()
        }

        if index < source.endIndex {
            advance()
        }

        return makeToken(.stringLiteral, text, sLine, sColumn)
    }

    mutating func scanCharLiteral() -> Token {
        let startLine = line
        let startColumn = column

        advance()

        var text = ""

        while index < source.endIndex, source[index] != "'" {
            if source[index] == "\\" {
                advance()

                if index < source.endIndex {
                    text.append(source[index])
                    advance()
                }

                continue
            }

            text.append(source[index])
            advance()
        }

        if index < source.endIndex {
            advance()
        }

        return makeToken(.integerLiteral, text, startLine, startColumn)
    }

    mutating func scanIdentifierOrKeyword() -> Token {
        let startLine = line
        let startColumn = column
        var text = ""

        while index < source.endIndex, source[index].isLetter || source[index].isNumber || source[index] == "_" {
            text.append(source[index])
            advance()
        }

        let kind = CLanguageVocabulary.classifyWord(text)
        return makeToken(kind, text, startLine, startColumn)
    }

    mutating func scanNumber() -> Token {
        let startLine = line
        let startColumn = column
        var text = ""
        var isFloat = false

        if source[index] == "0", peek(offset: 1) == "x" || peek(offset: 1) == "X" {
            text.append(source[index])
            advance()
            text.append(source[index])
            advance()

            while index < source.endIndex, source[index].isHexDigit {
                text.append(source[index])
                advance()
            }

            return makeToken(.integerLiteral, text, startLine, startColumn)
        }

        while index < source.endIndex, source[index].isNumber {
            text.append(source[index])
            advance()
        }

        if index < source.endIndex, source[index] == ".", peek(offset: 1)?.isNumber == true {
            isFloat = true
            text.append(source[index])
            advance()

            while index < source.endIndex, source[index].isNumber {
                text.append(source[index])
                advance()
            }
        }

        if index < source.endIndex, source[index] == "e" || source[index] == "E" {
            isFloat = true
            text.append(source[index])
            advance()

            if index < source.endIndex, source[index] == "+" || source[index] == "-" {
                text.append(source[index])
                advance()
            }

            while index < source.endIndex, source[index].isNumber {
                text.append(source[index])
                advance()
            }
        }

        skipNumericSuffix()

        return makeToken(isFloat ? .floatingLiteral : .integerLiteral, text, startLine, startColumn)
    }

    mutating func scanOperator() -> Token {
        let startLine = line
        let startColumn = column
        let char = source[index]
        let next = peek(offset: 1)

        if let next {
            let twoChar = String([char, next])

            if CLanguageVocabulary.twoCharOperators.contains(twoChar) {
                advance()
                advance()
                return makeToken(.operatorToken, twoChar, startLine, startColumn)
            }
        }

        advance()
        return makeToken(.operatorToken, String(char), startLine, startColumn)
    }

    mutating func scanPunctuation() -> Token {
        let startLine = line
        let startColumn = column
        let char = source[index]
        advance()
        return makeToken(.punctuation, String(char), startLine, startColumn)
    }

    private mutating func skipNumericSuffix() {
        let suffixChars: Set<Character> = ["f", "F", "l", "L", "u", "U"]

        while index < source.endIndex, suffixChars.contains(source[index]) {
            advance()
        }
    }
}
