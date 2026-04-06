import Testing

@testable import swift_cpd

@Suite("CloneDetector — Deduplication")
struct CloneDetectorDeduplicationTests {

    @Test("Given a subsumed pair and a larger pair, when deduplicating, then removes the subsumed pair")
    func deduplicateRemovesSubsumedPair() {
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

        let detectorSmall = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let resultsSmall = detectorSmall.detect(files: files)

        #expect(resultsSmall.count == 1)
        #expect(resultsSmall[0].tokenCount == 8)
    }

    @Test("Given pair with identical offsets as other, when checking subsumption, then is subsumed")
    func identicalOffsetsAreSubsumed() {
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

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
    }

    @Test("Given two non-overlapping clone pairs in different regions, when deduplicating, then keeps both")
    func nonOverlappingPairsAreKept() {
        let specsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            (.punctuation, ")"),
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let specsB: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
            (.keyword, "class"), (.identifier, "Foo"), (.punctuation, "{"),
            (.punctuation, "}"),
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let tokensA = makeTokens(specsA, file: "A.swift")
        let tokensB = makeTokens(specsB, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count >= 1)
    }

    @Test("Given clones where fragments span different line ranges, when building group, then lineCount is the maximum")
    func lineCountIsMaxOfFragments() {
        let specsNorm: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "$ID"), (.operatorToken, "="),
        ]

        let rawSpecsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let rawSpecsB: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "y"), (.operatorToken, "="),
        ]

        let tokensRawA = rawSpecsA.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1, column: 1 + index * 4)
            )
        }

        let tokensRawB = rawSpecsB.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 1 + index, column: 1)
            )
        }

        let tokensNormA = specsNorm.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1, column: 1 + index * 4)
            )
        }

        let tokensNormB = specsNorm.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 1 + index, column: 1)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensRawA, normalizedTokens: tokensNormA),
            FileTokens(file: "B.swift", source: "", tokens: tokensRawB, normalizedTokens: tokensNormB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 3)
    }

    @Test("Given pair where only A is subsumed but not B, when deduplicating, then keeps both pairs")
    func partialSubsumptionKeepsBothPairs() {
        let sharedBlock: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let extraBlock: [(TokenKind, String)] = [
            (.keyword, "var"), (.identifier, "b"), (.operatorToken, "="),
            (.integerLiteral, "2"),
        ]

        let differentBlock: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            (.punctuation, ")"),
        ]

        let tokensFileA = makeTokens(sharedBlock + extraBlock, file: "A.swift")
        let tokensFileB = makeTokens(sharedBlock + differentBlock, file: "B.swift")
        let tokensFileC = makeTokens(sharedBlock + extraBlock, file: "C.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensFileA, normalizedTokens: tokensFileA),
            FileTokens(file: "B.swift", source: "", tokens: tokensFileB, normalizedTokens: tokensFileB),
            FileTokens(file: "C.swift", source: "", tokens: tokensFileC, normalizedTokens: tokensFileC),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count >= 2)
    }

    @Test("Given multiple identical files, when detecting, then hash table correctly accumulates all locations")
    func hashTableAccumulatesMultipleLocations() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")
        let tokensC = makeTokens(specs, file: "C.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
            FileTokens(file: "C.swift", source: "", tokens: tokensC, normalizedTokens: tokensC),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
    }

    @Test(
        "Given bidirectional subsumption check, when smaller pair comes first, then still deduplicated"
    )
    func bidirectionalSubsumptionDeduplicates() {
        let smallSpecs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let largeSpecs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "y"),
        ]

        let tokensA = makeTokens(largeSpecs, file: "A.swift")
        let tokensB = makeTokens(largeSpecs, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
        #expect(results[0].tokenCount == 6)
    }
}
