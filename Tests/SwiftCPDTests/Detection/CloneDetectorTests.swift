import Testing

@testable import swift_cpd

@Suite("CloneDetector")
struct CloneDetectorTests {

    @Test("Given identical fragments in two files, when detecting, then returns Type-1 clone")
    func detectsType1Clone() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "y"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].type == .type1)
    }

    @Test("Given parameterized fragments in two files, when detecting, then returns Type-2 clone")
    func detectsType2Clone() {
        let normalizedSpecs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "$ID"), (.operatorToken, "="),
            (.integerLiteral, "$NUM"), (.keyword, "var"), (.identifier, "$ID"),
        ]

        let rawSpecsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "foo"), (.operatorToken, "="),
            (.integerLiteral, "42"), (.keyword, "var"), (.identifier, "bar"),
        ]

        let rawSpecsB: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "baz"), (.operatorToken, "="),
            (.integerLiteral, "99"), (.keyword, "var"), (.identifier, "qux"),
        ]

        let files = [
            FileTokens(
                file: "A.swift",
                source: "",
                tokens: makeTokens(rawSpecsA, file: "A.swift"),
                normalizedTokens: makeTokens(normalizedSpecs, file: "A.swift")
            ),
            FileTokens(
                file: "B.swift",
                source: "",
                tokens: makeTokens(rawSpecsB, file: "B.swift"),
                normalizedTokens: makeTokens(normalizedSpecs, file: "B.swift")
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].type == .type2)
    }

    @Test("Given unrelated code in two files, when detecting, then returns no clones")
    func noFalsePositives() {
        let specsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "let"), (.identifier, "y"),
        ]

        let specsB: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            (.punctuation, ")"), (.punctuation, "{"), (.punctuation, "}"),
        ]

        let files = [
            FileTokens(
                file: "A.swift",
                source: "",
                tokens: makeTokens(specsA, file: "A.swift"),
                normalizedTokens: makeTokens(specsA, file: "A.swift")
            ),
            FileTokens(
                file: "B.swift",
                source: "",
                tokens: makeTokens(specsB, file: "B.swift"),
                normalizedTokens: makeTokens(specsB, file: "B.swift")
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given matching tokens beyond initial window, when detecting, then expands to maximal region")
    func regionExpansion() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "y"),
            (.operatorToken, "="), (.integerLiteral, "2"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].tokenCount == 8)
    }

    @Test("Given overlapping clone pairs, when detecting, then deduplicates to single result")
    func deduplicatesOverlappingClones() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "y"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
    }

    @Test("Given files shorter than minimumTokenCount, when detecting, then returns no clones")
    func respectsMinimumTokenCount() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given clones spanning fewer lines than threshold, when detecting, then filters them out")
    func respectsMinimumLineCount() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let tokensA = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1, column: 1 + index * 4)
            )
        }

        let tokensB = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 1, column: 1 + index * 4)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 5)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given repeating tokens in same file, when overlapping candidates exist, then skips overlapping pairs")
    func overlappingCandidatesSkipped() {
        let repeatingUnit: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let specs = repeatingUnit + repeatingUnit + repeatingUnit

        let tokensA = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1 + index, column: 1)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA)
        ]

        let detector = CloneDetector(minimumTokenCount: 6, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }
}
