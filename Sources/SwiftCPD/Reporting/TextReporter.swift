struct TextReporter: Reporter {

    func report(_ result: AnalysisResult) -> String {
        let clones = result.sortedCloneGroups
        let timeFormatted = String(format: "%.2f", result.executionTime)

        guard
            !clones.isEmpty
        else {
            return "No clones detected in \(result.filesAnalyzed) files (\(timeFormatted)s)"
        }

        var lines: [String] = []
        lines.append("Found \(clones.count) clone(s) in \(result.filesAnalyzed) files (\(timeFormatted)s)")

        for (index, clone) in clones.enumerated() {
            lines.append("")
            let header =
                "Clone \(index + 1) " + "(Type-\(clone.type.rawValue), " + "\(clone.tokenCount) tokens, "
                + "\(clone.lineCount) lines):"
            lines.append(header)

            for fragment in clone.fragments {
                lines.append("  \(fragment.file):\(fragment.startLine)-\(fragment.endLine)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
