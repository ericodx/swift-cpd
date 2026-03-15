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

        let basename = (filePath as NSString).lastPathComponent

        return compiledPatterns.contains { compiled in
            let target = compiled.basenameOnly ? basename : filePath
            let range = NSRange(target.startIndex..., in: target)
            return compiled.regex.firstMatch(in: target, range: range) != nil
        }
    }
}

extension GlobMatcher {

    private static func convertGlobToRegex(_ glob: String) -> String {
        var regex = ""
        var index = glob.startIndex

        while index < glob.endIndex {
            let char = glob[index]

            switch char {
            case "*":
                let next = glob.index(after: index)

                if next < glob.endIndex, glob[next] == "*" {
                    let afterStars = glob.index(after: next)

                    if afterStars < glob.endIndex, glob[afterStars] == "/" {
                        regex += "(.+/)?"
                        index = glob.index(after: afterStars)
                        continue
                    }

                    regex += ".*"
                    index = glob.index(after: next)
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

            index = glob.index(after: index)
        }

        return "^" + regex + "$"
    }
}
