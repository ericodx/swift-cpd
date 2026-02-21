import Foundation

struct JsonReporter: Reporter {

    func report(_ result: AnalysisResult) -> String {
        let clones = result.sortedCloneGroups
        let report = buildReport(from: clones, result: result)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard
            let data = try? encoder.encode(report),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return json
    }
}

extension JsonReporter {

    private func buildReport(from clones: [CloneGroup], result: AnalysisResult) -> JsonReport {
        let executionTimeMs = Int(result.executionTime * 1000)

        let metadata = JsonMetadata(
            configuration: JsonConfiguration(
                minimumLineCount: result.minimumLineCount,
                minimumTokenCount: result.minimumTokenCount
            ),
            executionTimeMs: executionTimeMs,
            filesAnalyzed: result.filesAnalyzed,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            totalTokens: result.totalTokens
        )

        let jsonClones = clones.enumerated().map { index, clone in
            JsonClone(
                fragments: clone.fragments.map { fragment in
                    JsonFragment(
                        endColumn: fragment.endColumn,
                        endLine: fragment.endLine,
                        file: fragment.file,
                        preview: readPreview(for: fragment),
                        startColumn: fragment.startColumn,
                        startLine: fragment.startLine
                    )
                },
                id: String(format: "clone-%03d", index + 1),
                lineCount: clone.lineCount,
                similarity: clone.similarity,
                tokenCount: clone.tokenCount,
                type: clone.type.rawValue
            )
        }

        let summary = buildSummary(from: clones, totalTokens: result.totalTokens)

        return JsonReport(
            clones: jsonClones,
            metadata: metadata,
            summary: summary,
            version: "1.0.0"
        )
    }

    private func readPreview(for fragment: CloneFragment) -> String {
        guard
            let content = try? String(contentsOfFile: fragment.file, encoding: .utf8)
        else {
            return ""
        }

        let lines = content.components(separatedBy: "\n")
        let startIndex = fragment.startLine - 1
        let endIndex = min(fragment.endLine - 1, lines.count - 1)

        let firstLine = lines[startIndex].trimmingCharacters(in: .whitespaces)

        if startIndex == endIndex {
            return firstLine
        }

        return firstLine + " ... }"
    }

    private func buildSummary(from clones: [CloneGroup], totalTokens: Int) -> JsonSummary {
        var type1 = 0
        var type2 = 0
        var type3 = 0
        var type4 = 0

        for clone in clones {
            switch clone.type {
            case .type1:
                type1 += 1

            case .type2:
                type2 += 1

            case .type3:
                type3 += 1

            case .type4:
                type4 += 1
            }
        }

        let duplicatedTokens = clones.reduce(0) { $0 + $1.tokenCount }

        let duplicationPercentage = DuplicationCalculator.percentage(
            duplicatedTokens: duplicatedTokens,
            totalTokens: totalTokens
        )

        return JsonSummary(
            byType: JsonByType(
                type1: type1,
                type2: type2,
                type3: type3,
                type4: type4
            ),
            duplicatedLines: clones.reduce(0) { $0 + $1.lineCount },
            duplicatedTokens: duplicatedTokens,
            duplicationPercentage: duplicationPercentage,
            totalClones: clones.count
        )
    }
}
