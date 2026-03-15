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

        let searchStart = firstTokenIndex(atOrAfterLine: startLine, in: tokens)

        for index in searchStart ..< tokens.count {
            let line = tokens[index].location.line

            if line > endLine {
                break
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

    private func firstTokenIndex(atOrAfterLine line: Int, in tokens: [Token]) -> Int {
        var low = 0
        var high = tokens.count

        while low < high {
            let mid = (low + high) / 2

            if tokens[mid].location.line < line {
                low = mid + 1
            } else {
                high = mid
            }
        }

        return low
    }
}
