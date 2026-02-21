import Testing

@testable import swift_cpd

@Suite("GlobMatcher")
struct GlobMatcherTests {

    @Test("Given no patterns, when matching, then returns false")
    func emptyPatternsNeverMatch() {
        let matcher = GlobMatcher(patterns: [])

        #expect(matcher.matches("Sources/File.swift") == false)
    }

    @Test("Given single wildcard pattern, when matching file, then matches by extension")
    func singleWildcardMatchesExtension() {
        let matcher = GlobMatcher(patterns: ["*.generated.swift"])

        #expect(matcher.matches("Model.generated.swift") == true)
        #expect(matcher.matches("Model.swift") == false)
    }

    @Test("Given double wildcard pattern, when matching nested path, then matches recursively")
    func doubleWildcardMatchesRecursively() {
        let matcher = GlobMatcher(patterns: ["**/Generated/**"])

        #expect(matcher.matches("Sources/Generated/File.swift") == true)
        #expect(matcher.matches("Generated/File.swift") == true)
        #expect(matcher.matches("Sources/File.swift") == false)
    }

    @Test("Given directory pattern, when matching, then matches files in directory")
    func directoryPatternMatchesContents() {
        let matcher = GlobMatcher(patterns: ["Build/*"])

        #expect(matcher.matches("Build/output.swift") == true)
        #expect(matcher.matches("Build/sub/output.swift") == false)
        #expect(matcher.matches("Sources/output.swift") == false)
    }

    @Test("Given question mark pattern, when matching, then matches single character")
    func questionMarkMatchesSingleChar() {
        let matcher = GlobMatcher(patterns: ["file?.swift"])

        #expect(matcher.matches("file1.swift") == true)
        #expect(matcher.matches("fileAB.swift") == false)
    }

    @Test("Given multiple patterns, when matching, then matches any pattern")
    func multiplePatternsMatchAny() {
        let matcher = GlobMatcher(patterns: [
            "*.generated.swift",
            "**/Pods/**",
        ])

        #expect(matcher.matches("Model.generated.swift") == true)
        #expect(matcher.matches("Vendor/Pods/Lib/File.swift") == true)
        #expect(matcher.matches("Sources/File.swift") == false)
    }

    @Test("Given pattern with dots, when matching, then dots are literal")
    func dotsAreLiteral() {
        let matcher = GlobMatcher(patterns: ["*.swift"])

        #expect(matcher.matches("File.swift") == true)
        #expect(matcher.matches("Filexswift") == false)
    }

    @Test("Given double wildcard with trailing slash, when matching deep path, then matches")
    func doubleWildcardDeepPath() {
        let matcher = GlobMatcher(patterns: ["**/Tests/**"])

        #expect(matcher.matches("Project/Tests/Unit/Test.swift") == true)
        #expect(matcher.matches("Tests/Test.swift") == true)
    }

    @Test("Given pattern without wildcards, when matching exact path, then matches")
    func exactPathMatch() {
        let matcher = GlobMatcher(patterns: ["Sources/Generated.swift"])

        #expect(matcher.matches("Sources/Generated.swift") == true)
        #expect(matcher.matches("Sources/Other.swift") == false)
    }

    @Test("Given pattern with regex special characters, when matching, then treats them literally")
    func regexSpecialCharsAreLiteral() {
        let matcher = GlobMatcher(patterns: ["file(1).swift"])

        #expect(matcher.matches("file(1).swift") == true)
        #expect(matcher.matches("fileX1Y.swift") == false)
    }

    @Test("Given double wildcard at end, when matching, then matches everything below")
    func doubleWildcardAtEnd() {
        let matcher = GlobMatcher(patterns: ["Vendor/**"])

        #expect(matcher.matches("Vendor/Lib/File.swift") == true)
        #expect(matcher.matches("Vendor/File.swift") == true)
    }

    @Test("Given invalid pattern producing bad regex, when creating matcher, then skips pattern gracefully")
    func invalidPatternSkipped() {
        let matcher = GlobMatcher(patterns: ["[invalid"])

        #expect(matcher.matches("anything.swift") == false)
    }
}
