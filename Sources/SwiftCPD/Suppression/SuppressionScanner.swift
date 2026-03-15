struct SuppressionScanner: Sendable {

    init(tag: String = "swiftcpd:ignore") {
        self.tag = tag
    }

    let tag: String

    func suppressedLines(in source: String) -> Set<Int> {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var suppressed = Set<Int>()
        var lineNumber = 1

        while lineNumber <= lines.count {
            let line = lines[lineNumber - 1]
            let trimmed = line.drop(while: { $0.isWhitespace })

            guard
                containsSuppressionTag(trimmed)
            else {
                lineNumber += 1
                continue
            }

            lineNumber += 1
            let range = findSuppressedRange(from: lineNumber, in: lines)

            for suppressedLine in range {
                suppressed.insert(suppressedLine)
            }

            lineNumber = range.upperBound + 1
        }

        return suppressed
    }
}

extension SuppressionScanner {

    private func containsSuppressionTag(_ line: Substring) -> Bool {
        if line.hasPrefix("//") {
            let comment = line.dropFirst(2).drop(while: { $0.isWhitespace })
            return comment.hasPrefix(tag)
        }

        if line.hasPrefix("/*") {
            let comment = line.dropFirst(2).drop(while: { $0.isWhitespace })
            return comment.hasPrefix(tag)
        }

        return false
    }

    private func findSuppressedRange(
        from startLine: Int,
        in lines: [Substring]
    ) -> ClosedRange<Int> {
        guard
            startLine <= lines.count
        else {
            return startLine ... startLine
        }

        let firstContentLine = findNextContentLine(from: startLine, in: lines)

        guard
            firstContentLine <= lines.count
        else {
            return startLine ... startLine
        }

        let firstLine = lines[firstContentLine - 1]

        guard
            firstLine.contains("{")
        else {
            return firstContentLine ... firstContentLine
        }

        return findBlockEnd(from: firstContentLine, in: lines)
    }

    private func findNextContentLine(from startLine: Int, in lines: [Substring]) -> Int {
        var line = startLine

        while line <= lines.count {
            let content = lines[line - 1].drop(while: { $0.isWhitespace })

            if !content.isEmpty {
                return line
            }

            line += 1
        }

        return line
    }

    private func findBlockEnd(from startLine: Int, in lines: [Substring]) -> ClosedRange<Int> {
        var depth = 0
        var line = startLine

        while line <= lines.count {
            let content = lines[line - 1]

            for char in content {
                if char == "{" {
                    depth += 1
                } else if char == "}" {
                    depth -= 1

                    if depth == 0 {
                        return startLine ... line
                    }
                }
            }

            line += 1
        }

        return startLine ... (line - 1)
    }
}
