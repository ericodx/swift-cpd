import Foundation

struct HtmlReporter: Reporter {

    func report(_ result: AnalysisResult) -> String {
        let clones = result.sortedCloneGroups
        let timeFormatted = String(format: "%.2f", result.executionTime)

        return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <title>swift-cpd Report</title>
                <style>
            \(css)
                </style>
            </head>
            <body>
                <div class="summary">
                    <h1>swift-cpd Report</h1>
                    <p>\(clones.count) clone(s) found \
            in \(result.filesAnalyzed) files (\(timeFormatted)s)</p>
                </div>
            \(clones.isEmpty ? renderNoClones() : renderClones(clones))
            </body>
            </html>
            """
    }
}

extension HtmlReporter {

    private var css: String {
        """
        body {
            font-family: -apple-system, sans-serif;
            margin: 40px;
            background: #f5f5f7;
            color: #1d1d1f;
        }
        .summary {
            background: #fff;
            padding: 24px;
            border-radius: 12px;
            margin-bottom: 24px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .summary h1 { margin: 0 0 8px 0; font-size: 24px; }
        .summary p { margin: 0; color: #6e6e73; }
        .clone {
            background: #fff;
            padding: 20px;
            border-radius: 12px;
            margin-bottom: 16px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .clone-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
        }
        .clone-number { font-weight: 600; font-size: 16px; }
        .badge {
            padding: 2px 10px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            color: #fff;
        }
        .type-1 { background: #34c759; }
        .type-2 { background: #007aff; }
        .type-3 { background: #ff9500; }
        .type-4 { background: #ff3b30; }
        .meta { color: #6e6e73; font-size: 14px; }
        .fragments { list-style: none; padding: 0; margin: 0; }
        .fragments li {
            padding: 6px 12px;
            font-family: 'SF Mono', Menlo, monospace;
            font-size: 13px;
            color: #1d1d1f;
            background: #f5f5f7;
            border-radius: 6px;
            margin-bottom: 4px;
        }
        .no-clones {
            text-align: center;
            padding: 48px;
            color: #6e6e73;
            font-size: 18px;
        }
        """
    }

    private func renderNoClones() -> String {
        """
            <div class="no-clones">No clones detected.</div>
        """
    }

    private func renderClones(_ clones: [CloneGroup]) -> String {
        clones.enumerated().map { index, clone in
            renderClone(clone, number: index + 1)
        }.joined(separator: "\n")
    }

    private func renderClone(_ clone: CloneGroup, number: Int) -> String {
        let fragmentsHtml = clone.fragments.map { fragment in
            let escaped = escapeHtml(fragment.file)
            return "            <li>\(escaped):\(fragment.startLine)-\(fragment.endLine)</li>"
        }.joined(separator: "\n")

        return """
                <div class="clone">
                    <div class="clone-header">
                        <span class="clone-number">Clone \(number)</span>
                        <span class="badge type-\(clone.type.rawValue)">\
            Type-\(clone.type.rawValue)</span>
                        <span class="meta">\
            \(clone.tokenCount) tokens, \(clone.lineCount) lines</span>
                    </div>
                    <ul class="fragments">
            \(fragmentsHtml)
                    </ul>
                </div>
            """
    }

    private func escapeHtml(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
