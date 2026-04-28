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

    @Test("Given file with exactly minimumTokenCount tokens, when detecting, then processes the file")
    func exactlyMinimumTokenCountIsProcessed() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
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
    }

    @Test("Given hash with single location, when filtering candidates, then excludes it")
    func singleLocationHashProducesNoCandidates() {
        let specsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let specsB: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
        ]

        let tokensA = makeTokens(specsA, file: "A.swift")
        let tokensB = makeTokens(specsB, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given clones with lineCount exactly equal to minimumLineCount, when filtering, then includes them")
    func lineCountExactlyAtMinimumIsIncluded() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"),
        ]

        let tokensA = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1 + index, column: 1)
            )
        }

        let tokensB = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 1 + index, column: 1)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 5)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 5)
    }

    @Test(
        "Given same-file tokens with distance equal to minimumTokenCount, when checking overlap, then not overlapping"
    )
    func distanceEqualToMinimumTokenCountIsNotOverlapping() {
        let unit: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let specs =
            unit + [
                (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            ] + unit

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

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
    }

    @Test("Given same-file tokens with distance less than minimumTokenCount, when checking overlap, then overlapping")
    func distanceLessThanMinimumTokenCountIsOverlapping() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

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

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test(
        "Given static let declarations with different types, when detecting, then returns no Type-2 clones"
    )
    func noFalsePositivesForDifferentTypes() {
        let sourceA = """
            public enum DSColors {
                public enum Black {
                    public static let solid = Color(r: 0, g: 0, b: 0)
                    public static let opacity10 = Color(r: 0, g: 0, b: 0, a: 0.1)
                    public static let opacity20 = Color(r: 0, g: 0, b: 0, a: 0.2)
                    public static let opacity30 = Color(r: 0, g: 0, b: 0, a: 0.3)
                    public static let opacity40 = Color(r: 0, g: 0, b: 0, a: 0.4)
                    public static let opacity50 = Color(r: 0, g: 0, b: 0, a: 0.5)
                }
            }
            """

        let sourceB = """
            public enum DSGrids {
                public enum Desktop {
                    public static let columns2 = GridToken(columns: 2, gutter: 32, margin: 0, totalWidth: 1280)
                    public static let columns4 = GridToken(columns: 4, gutter: 32, margin: 0, totalWidth: 1280)
                    public static let columns6 = GridToken(columns: 6, gutter: 32, margin: 0, totalWidth: 1280)
                    public static let columns8 = GridToken(columns: 8, gutter: 32, margin: 0, totalWidth: 1280)
                    public static let columns10 = GridToken(columns: 10, gutter: 32, margin: 0, totalWidth: 1280)
                    public static let columns12 = GridToken(columns: 12, gutter: 32, margin: 0, totalWidth: 1280)
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "DSColors.swift")
        let fileB = makeFileTokens(source: sourceB, file: "DSGrids.swift")

        let detector = CloneDetector(minimumTokenCount: 20, minimumLineCount: 3)
        let results = detector.detect(files: [fileA, fileB])

        let crossFileClones = results.filter { group in
            let files = Set(group.fragments.map(\.file))
            return files.count > 1
        }

        #expect(crossFileClones.isEmpty)
    }

    @Test(
        "Given real-world design tokens with different types, when detecting, then returns no cross-file Type-2 clones"
    )
    func noFalsePositivesForRealWorldDesignTokens() {
        let sourceA = """
            public enum DSColors {
                public enum Black {
                    public static let solid = Color(r: 0, g: 0, b: 0)
                    public static let opacity10 = Color(r: 0, g: 0, b: 0, a: 0.1)
                    public static let opacity20 = Color(r: 0, g: 0, b: 0, a: 0.2)
                    public static let opacity30 = Color(r: 0, g: 0, b: 0, a: 0.3)
                    public static let opacity40 = Color(r: 0, g: 0, b: 0, a: 0.4)
                    public static let opacity50 = Color(r: 0, g: 0, b: 0, a: 0.5)
                    public static let opacity60 = Color(r: 0, g: 0, b: 0, a: 0.6)
                    public static let opacity70 = Color(r: 0, g: 0, b: 0, a: 0.7)
                    public static let opacity80 = Color(r: 0, g: 0, b: 0, a: 0.8)
                    public static let opacity90 = Color(r: 0, g: 0, b: 0, a: 0.9)
                    public static let opacity100 = Color(r: 0, g: 0, b: 0)
                }
                public enum White {
                    public static let solid = Color(r: 255, g: 255, b: 255)
                    public static let opacity10 = Color(r: 255, g: 255, b: 255, a: 0.1)
                    public static let opacity20 = Color(r: 255, g: 255, b: 255, a: 0.2)
                    public static let opacity30 = Color(r: 255, g: 255, b: 255, a: 0.3)
                    public static let opacity40 = Color(r: 255, g: 255, b: 255, a: 0.4)
                    public static let opacity50 = Color(r: 255, g: 255, b: 255, a: 0.5)
                    public static let opacity60 = Color(r: 255, g: 255, b: 255, a: 0.6)
                    public static let opacity70 = Color(r: 255, g: 255, b: 255, a: 0.7)
                    public static let opacity80 = Color(r: 255, g: 255, b: 255, a: 0.8)
                    public static let opacity90 = Color(r: 255, g: 255, b: 255, a: 0.9)
                    public static let opacity100 = Color(r: 255, g: 255, b: 255)
                }
            }
            """

        let sourceB = """
            public enum DSGrids {
                public enum Desktop {
                    public static let columns2 = GridToken(
                        columns: 2, gutter: 32, margin: 0, totalWidth: 1280
                    )
                    public static let columns4 = GridToken(
                        columns: 4, gutter: 32, margin: 0, totalWidth: 1280
                    )
                    public static let columns6 = GridToken(
                        columns: 6, gutter: 32, margin: 0, totalWidth: 1280
                    )
                    public static let columns12 = GridToken(
                        columns: 12, gutter: 32, margin: 0, totalWidth: 1280
                    )
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "DSColors.swift")
        let fileB = makeFileTokens(source: sourceB, file: "DSGrids.swift")

        let detector = CloneDetector(minimumTokenCount: 50, minimumLineCount: 5)
        let results = detector.detect(files: [fileA, fileB])

        let crossFileClones = results.filter { group in
            let files = Set(group.fragments.map(\.file))
            return files.count > 1
        }

        #expect(crossFileClones.isEmpty)
    }

    @Test("Given tokens that match at end boundary, when expanding, then expands to end of tokens")
    func expansionReachesEndOfTokens() {
        let sharedSpecs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let extraToken: [(TokenKind, String)] = [(.integerLiteral, "42")]

        let specsA = sharedSpecs + extraToken
        let specsB = sharedSpecs + extraToken

        let tokensA = makeTokens(specsA, file: "A.swift")
        let tokensB = makeTokens(specsB, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].tokenCount == 4)
    }

}
