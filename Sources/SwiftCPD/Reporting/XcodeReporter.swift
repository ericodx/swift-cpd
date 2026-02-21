struct XcodeReporter: Reporter {

    func report(_ result: AnalysisResult) -> String {
        let clones = result.sortedCloneGroups

        var lines: [String] = []

        for clone in clones {
            for (index, fragment) in clone.fragments.enumerated() {
                let otherFragments = clone.fragments.enumerated()
                    .filter { $0.offset != index }
                    .map { otherFragment in
                        let fileName = extractFileName(from: otherFragment.element.file)
                        return "\(fileName):\(otherFragment.element.startLine)"
                    }
                    .joined(separator: ", ")

                let description =
                    "Type-\(clone.type.rawValue), \(clone.tokenCount) tokens, \(clone.lineCount) lines"

                let location = "\(fragment.file):\(fragment.startLine):\(fragment.startColumn)"
                let message = "Clone detected (\(description)) \u{2014} also in \(otherFragments)"
                lines.append("\(location): warning: \(message)")
            }
        }

        return lines.joined(separator: "\n")
    }
}

extension XcodeReporter {

    private func extractFileName(from path: String) -> String {
        guard
            let lastSlash = path.lastIndex(of: "/")
        else {
            return path
        }

        return String(path[path.index(after: lastSlash)...])
    }
}
