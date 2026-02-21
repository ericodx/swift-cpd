import SwiftParser
import SwiftSyntax

struct BlockExtractor: Sendable {

    func extract(source: String, file: String, tokens: [Token]) -> [CodeBlock] {
        let sourceFile = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: file, tree: sourceFile)
        let visitor = BlockVisitor(converter: converter)
        visitor.walk(sourceFile)

        return visitor.lineRanges.compactMap { range in
            mapToTokenRange(
                startLine: range.startLine,
                endLine: range.endLine,
                file: file,
                tokens: tokens
            )
        }
    }
}

extension BlockExtractor {

    private func mapToTokenRange(
        startLine: Int,
        endLine: Int,
        file: String,
        tokens: [Token]
    ) -> CodeBlock? {
        var startIndex: Int?
        var endIndex: Int?

        for (index, token) in tokens.enumerated() {
            guard
                token.location.line >= startLine,
                token.location.line <= endLine
            else {
                if token.location.line > endLine {
                    break
                }

                continue
            }

            if startIndex == nil {
                startIndex = index
            }

            endIndex = index
        }

        guard
            let start = startIndex,
            let end = endIndex
        else {
            return nil
        }

        return CodeBlock(
            file: file,
            startLine: startLine,
            endLine: endLine,
            startTokenIndex: start,
            endTokenIndex: end
        )
    }
}
