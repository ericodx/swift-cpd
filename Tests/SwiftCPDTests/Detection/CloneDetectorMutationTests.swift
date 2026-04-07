import Testing

@testable import swift_cpd

@Suite("CloneDetector Mutation")
struct CloneDetectorMutationTests {

    @Test("Given unique token sequences per file, when each hash has exactly one location, then no clones detected")
    func hashWithExactlyOneLocationProducesNoCandidates() {
        let specsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"),
        ]

        let specsB: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"), (.punctuation, "("),
            (.punctuation, ")"), (.punctuation, "{"),
        ]

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: makeTokens(specsA, file: "A.swift"),
                normalizedTokens: makeTokens(specsA, file: "A.swift")
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: makeTokens(specsB, file: "B.swift"),
                normalizedTokens: makeTokens(specsB, file: "B.swift")
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given pair subsumed in one direction only, when deduplicating with OR logic, then removes duplicate")
    func deduplicationRemovesOneDirectionSubsumedPair() {
        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "b"),
        ]

        let extra: [(TokenKind, String)] = [
            (.operatorToken, "="), (.integerLiteral, "2"),
        ]

        let longerA = shared + extra
        let longerB = shared + extra

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: makeTokens(longerA, file: "A.swift"),
                normalizedTokens: makeTokens(longerA, file: "A.swift")
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: makeTokens(longerB, file: "B.swift"),
                normalizedTokens: makeTokens(longerB, file: "B.swift")
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
        #expect(results[0].tokenCount == 8)
    }

    @Test("Given same-file clones at boundary, when checking overlap, then abs arithmetic correct")
    func overlapAbsArithmeticWithReversedOffsets() {
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

        #expect(results.count == 1)
    }

    @Test("Given same-file clones one less than minimum, when overlap uses strict less-than, then overlapping")
    func overlapStrictLessThanBoundary() {
        let unit: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
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

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
    }

    @Test("Given subsumption where pair A matches but pair B does not, when using AND logic, then not subsumed")
    func subsumptionRequiresAndNotOr() {
        let baseShared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "b"),
            (.operatorToken, "="), (.integerLiteral, "2"),
        ]

        let extraA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "c"),
        ]

        let differentB: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"),
        ]

        let fileATokens = makeTokens(baseShared + extraA, file: "A.swift")
        let fileBTokens = makeTokens(baseShared, file: "B.swift")
        let fileCTokens = makeTokens(baseShared + differentB, file: "C.swift")

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: fileATokens, normalizedTokens: fileATokens
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: fileBTokens, normalizedTokens: fileBTokens
            ),
            FileTokens(
                file: "C.swift", source: "",
                tokens: fileCTokens, normalizedTokens: fileCTokens
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count >= 2)
    }

    @Test("Given tokens spanning multiple lines, when building clone group, then lineCount uses correct arithmetic")
    func lineCountArithmeticEndMinusStartPlusOne() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let tokensA = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 5 + index, column: 1)
            )
        }

        let tokensB = specs.enumerated().map { index, spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 15 + index, column: 1)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 3)
    }

    @Test("Given single-line tokens, when lineCount computed, then returns 1 not 0 or 2")
    func lineCountForSingleLineIsOne() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let tokensA = specs.map { spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "A.swift", line: 1, column: 1)
            )
        }

        let tokensB = specs.map { spec in
            Token(
                kind: spec.0,
                text: spec.1,
                location: SourceLocation(file: "B.swift", line: 1, column: 1)
            )
        }

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 1)
    }

    @Test("Given tokens with mismatch at last position, when loop compares all, then detects mismatch")
    func tokensMatchDetectsMismatchAtLastPosition() {
        let specsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let specsB: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "2"),
        ]

        let normalizedA = makeTokens(specsA, file: "A.swift")
        let normalizedB = makeTokens(specsB, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: normalizedA, normalizedTokens: normalizedA),
            FileTokens(file: "B.swift", source: "", tokens: normalizedB, normalizedTokens: normalizedB),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given tokens with offset, when tokensMatch uses addition for index, then accesses correct elements")
    func tokensMatchIndexComputationWithOffset() {
        let prefix: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "run"),
        ]

        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
        ]

        let specsA = prefix + shared
        let specsB = shared

        let tokensA = makeTokens(specsA, file: "A.swift")
        let tokensB = makeTokens(specsB, file: "B.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].type == .type1)
    }

    @Test("Given isSubsumed with end computed via addition, when pair fits inside other, then is subsumed")
    func subsumptionEndComputedByAddition() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "b"),
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
        #expect(results[0].tokenCount == 6)
    }

    @Test("Given cross-file clones, when overlap check uses abs, then different files are never overlapping")
    func crossFileNeverOverlapping() {
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

    @Test("Given two-line clone, when lineCount computed, then returns 2")
    func lineCountTwoLinesReturnsTwo() {
        let tokensA = [
            Token(kind: .keyword, text: "let", location: SourceLocation(file: "A.swift", line: 10, column: 1)),
            Token(kind: .identifier, text: "x", location: SourceLocation(file: "A.swift", line: 10, column: 5)),
            Token(kind: .operatorToken, text: "=", location: SourceLocation(file: "A.swift", line: 11, column: 1)),
        ]

        let tokensB = [
            Token(kind: .keyword, text: "let", location: SourceLocation(file: "B.swift", line: 20, column: 1)),
            Token(kind: .identifier, text: "x", location: SourceLocation(file: "B.swift", line: 20, column: 5)),
            Token(kind: .operatorToken, text: "=", location: SourceLocation(file: "B.swift", line: 21, column: 1)),
        ]

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA),
            FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB),
        ]

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 2)
    }

    @Test("Given parameterized clone where raw tokens differ at last position, when classifying, then Type-2 detected")
    func tokensMatchCountBoundaryForClassification() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "$ID"), (.operatorToken, "="),
            (.integerLiteral, "$NUM"), (.keyword, "var"),
        ]

        let rawSpecsA: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "foo"), (.operatorToken, "="),
            (.integerLiteral, "42"), (.keyword, "var"),
        ]

        let rawSpecsB: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "bar"), (.operatorToken, "="),
            (.integerLiteral, "99"), (.keyword, "var"),
        ]

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: makeTokens(rawSpecsA, file: "A.swift"),
                normalizedTokens: makeTokens(specs, file: "A.swift")
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: makeTokens(rawSpecsB, file: "B.swift"),
                normalizedTokens: makeTokens(specs, file: "B.swift")
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].type == .type2)
    }

    @Test("Given three files where AB and AC are clones, when deduplicating, then both pairs kept")
    func deduplicationKeepsNonSubsumedPairsFromDifferentFiles() {
        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let uniqueB: [(TokenKind, String)] = [
            (.keyword, "func"), (.identifier, "foo"), (.punctuation, "("),
            (.punctuation, ")"),
        ]

        let uniqueC: [(TokenKind, String)] = [
            (.keyword, "class"), (.identifier, "Bar"), (.punctuation, "{"),
            (.punctuation, "}"),
        ]

        let fileATokens = makeTokens(shared, file: "A.swift")
        let fileBTokens = makeTokens(shared + uniqueB, file: "B.swift")
        let fileCTokens = makeTokens(shared + uniqueC, file: "C.swift")

        let files = [
            FileTokens(file: "A.swift", source: "", tokens: fileATokens, normalizedTokens: fileATokens),
            FileTokens(file: "B.swift", source: "", tokens: fileBTokens, normalizedTokens: fileBTokens),
            FileTokens(file: "C.swift", source: "", tokens: fileCTokens, normalizedTokens: fileCTokens),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count >= 2)
    }

}
