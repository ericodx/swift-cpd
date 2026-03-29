import Foundation

struct GlobMatcher: Sendable {

    init(patterns: [String]) {
        self.compiledPatterns = patterns.compactMap { pattern in
            let regexString = Self.convertGlobToRegex(pattern)

            guard
                let regex = try? NSRegularExpression(pattern: regexString)
            else {
                return nil
            }

            let matchesBasenameOnly = !pattern.contains("/")
            return CompiledPattern(regex: regex, basenameOnly: matchesBasenameOnly)
        }
    }

    private let compiledPatterns: [CompiledPattern]

    func matches(_ filePath: String) -> Bool {
        guard
            !compiledPatterns.isEmpty
        else {
            return false
        }

        let basename = URL(fileURLWithPath: filePath).lastPathComponent

        return compiledPatterns.contains { compiled in
            let target = compiled.basenameOnly ? basename : filePath
            let range = NSRange(target.startIndex..., in: target)
            return compiled.regex.firstMatch(in: target, range: range) != nil
        }
    }
}

extension GlobMatcher {

    private static func convertGlobToRegex(_ glob: String) -> String {
        let isAbsolute = glob.hasPrefix("/")
        let hasTrailingSlash = glob.hasSuffix("/")
        let source = hasTrailingSlash ? String(glob.dropLast()) : glob

        var regex = ""
        var index = source.startIndex

        while index < source.endIndex {
            let char = source[index]

            switch char {
            case "*":
                let next = source.index(after: index)

                if next < source.endIndex, source[next] == "*" {
                    let afterStars = source.index(after: next)

                    if afterStars < source.endIndex, source[afterStars] == "/" {
                        regex += "(.+/)?"
                        index = source.index(after: afterStars)
                        continue
                    }

                    regex += ".*"
                    index = source.index(after: next)
                    continue
                }

                regex += "[^/]*"

            case "?":
                regex += "[^/]"

            case ".":
                regex += "\\."

            case "(", ")", "+", "^", "$", "|", "{", "}":
                regex += "\\\(char)"

            default:
                regex += String(char)
            }

            index = source.index(after: index)
        }

        let prefix = isAbsolute ? "^" : "(^|/)"
        let suffix = hasTrailingSlash ? "(/|$)" : "$"

        return prefix + regex + suffix
    }
}
