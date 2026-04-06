import Testing

@testable import swift_cpd

@Suite("CloneDetector Boundary")
struct CloneDetectorBoundaryTests {

    @Test("Given hash with exactly 2 locations, when filtering, then includes it")
    func hashWithExactlyTwoLocations() {
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

        #expect(results.count == 1)
    }

    @Test("Given distance exactly equal to minimumTokenCount, when checking, then not overlapping")
    func overlapDistanceExactlyEqualToMinTokenCount() {
        let unit: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let padding: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
        ]

        let specs = unit + padding + unit

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

    @Test("Given distance one less than minimumTokenCount, when checking, then overlapping")
    func overlapDistanceOneLessThanMinTokenCount() {
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

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given pair subsumed in A but not B, when checking, then not subsumed")
    func subsumptionRequiresBothFragments() {
        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let extra: [(TokenKind, String)] = [
            (.keyword, "var"), (.identifier, "b"), (.operatorToken, "="),
            (.integerLiteral, "2"),
        ]

        let different: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            (.punctuation, ")"),
        ]

        let tokensA = makeTokens(shared + extra, file: "A.swift")
        let tokensB = makeTokens(shared + different, file: "B.swift")
        let tokensC = makeTokens(shared + extra, file: "C.swift")

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: tokensA, normalizedTokens: tokensA
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: tokensB, normalizedTokens: tokensB
            ),
            FileTokens(
                file: "C.swift", source: "",
                tokens: tokensC, normalizedTokens: tokensC
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count >= 2)
    }

    @Test("Given pair with equal offsets, when checking subsumption, then subsumed")
    func subsumptionBoundaryOffsetsEqual() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"),
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
        #expect(results[0].tokenCount == 5)
    }

    @Test("Given pair with end exactly equal to other end, when checking, then subsumed")
    func subsumptionEndsBoundaryEqual() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
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
        #expect(results[0].tokenCount == 4)
    }

    @Test("Given fragments on different lines, when building group, then lineCount is correct")
    func cloneGroupLineCountArithmetic() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let tokensA = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 10 + index, column: 1)
            )
        }

        let tokensB = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 20 + index, column: 1)
            )
        }

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: tokensA, normalizedTokens: tokensA
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: tokensB, normalizedTokens: tokensB
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 4)
        #expect(results[0].fragments[0].startLine == 10)
        #expect(results[0].fragments[0].endLine == 13)
        #expect(results[0].fragments[1].startLine == 20)
        #expect(results[0].fragments[1].endLine == 23)
    }
}
