struct YamlConfigurationParser: Sendable {

    private enum ParseError: Error {
        case invalid
    }

    func parse(_ content: String) throws -> YamlConfiguration {
        var scalars: [String: String] = [:]
        var arrays: [String: [String]] = [:]
        var currentArrayKey: String?

        for line in content.components(separatedBy: .newlines) {
            let stripped = stripComment(line)
            let trimmed = stripped.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else {
                continue
            }

            if trimmed.hasPrefix("- ") {
                guard let key = currentArrayKey else {
                    throw ParseError.invalid
                }

                let item = String(trimmed.dropFirst(2))
                arrays[key, default: []].append(unquote(item))
                continue
            }

            currentArrayKey = nil

            guard let colonIndex = trimmed.firstIndex(of: ":") else {
                throw ParseError.invalid
            }

            let key = String(trimmed[..<colonIndex])
            let rawValue = String(trimmed[trimmed.index(after: colonIndex)...])
                .trimmingCharacters(in: .whitespaces)

            if rawValue.isEmpty {
                currentArrayKey = key
                arrays[key] = []
            } else if rawValue == "[]" {
                arrays[key] = []
            } else if rawValue.hasPrefix("[") {
                throw ParseError.invalid
            } else {
                scalars[key] = unquote(rawValue)
            }
        }

        return try buildConfiguration(scalars: scalars, arrays: arrays)
    }

    private func stripComment(_ line: String) -> String {
        guard !line.hasPrefix("#") else {
            return ""
        }

        guard let range = line.range(of: " #") else {
            return line
        }

        return String(line[..<range.lowerBound])
    }

    private func unquote(_ value: String) -> String {
        let isDoubleQuoted = value.hasPrefix("\"") && value.hasSuffix("\"")
        let isSingleQuoted = value.hasPrefix("'") && value.hasSuffix("'")

        guard (isDoubleQuoted || isSingleQuoted) && value.count >= 2 else {
            return value
        }

        return String(value.dropFirst().dropLast())
    }

    private func buildConfiguration(
        scalars: [String: String],
        arrays: [String: [String]]
    ) throws -> YamlConfiguration {
        YamlConfiguration(
            minimumTokenCount: try intValue(for: "minimumTokenCount", in: scalars),
            minimumLineCount: try intValue(for: "minimumLineCount", in: scalars),
            outputFormat: scalars["outputFormat"],
            paths: arrays["paths"],
            maxDuplication: try doubleValue(for: "maxDuplication", in: scalars),
            type3Similarity: try intValue(for: "type3Similarity", in: scalars),
            type3TileSize: try intValue(for: "type3TileSize", in: scalars),
            type3CandidateThreshold: try intValue(for: "type3CandidateThreshold", in: scalars),
            type4Similarity: try intValue(for: "type4Similarity", in: scalars),
            crossLanguageEnabled: try boolValue(for: "crossLanguageEnabled", in: scalars),
            exclude: arrays["exclude"],
            inlineSuppressionTag: scalars["inlineSuppressionTag"],
            enabledCloneTypes: try intArray(for: "enabledCloneTypes", in: arrays),
            ignoreSameFile: try boolValue(for: "ignoreSameFile", in: scalars),
            ignoreStructural: try boolValue(for: "ignoreStructural", in: scalars)
        )
    }

    private func intValue(for key: String, in scalars: [String: String]) throws -> Int? {
        guard let raw = scalars[key] else {
            return nil
        }

        guard let value = Int(raw) else {
            throw ParseError.invalid
        }

        return value
    }

    private func doubleValue(for key: String, in scalars: [String: String]) throws -> Double? {
        guard let raw = scalars[key] else {
            return nil
        }

        guard let value = Double(raw) else {
            throw ParseError.invalid
        }

        return value
    }

    private func boolValue(for key: String, in scalars: [String: String]) throws -> Bool? {
        guard let raw = scalars[key] else {
            return nil
        }

        switch raw.lowercased() {

        case "true", "yes":
            return true

        case "false", "no":
            return false

        default:
            throw ParseError.invalid

        }
    }

    private func intArray(for key: String, in arrays: [String: [String]]) throws -> [Int]? {
        guard let items = arrays[key] else {
            return nil
        }

        return try items.map { raw in
            guard let value = Int(raw) else {
                throw ParseError.invalid
            }

            return value
        }
    }
}
