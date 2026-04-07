import Testing

@testable import swift_cpd

@Suite("CloneDetector Mutation Boundary")
struct CloneDetectorMutationBoundaryTests {

    @Test("Given distance exactly at minimumTokenCount, when < not <=, then not overlapping")
    func overlapDistanceExactlyAtMinimum() {
        let minimumTokenCount = 3

        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
        ]

        var allTokens: [Token] = []
        for idx in 0 ..< 6 {
            allTokens.append(
                Token(
                    kind: specs[idx % 3].0,
                    text: specs[idx % 3].1,
                    location: SourceLocation(
                        file: "A.swift", line: 1 + idx, column: 1
                    )
                ))
        }

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: allTokens, normalizedTokens: allTokens
            )
        ]

        let detector = CloneDetector(
            minimumTokenCount: minimumTokenCount, minimumLineCount: 1
        )
        let results = detector.detect(files: files)

        #expect(results.count == 1)
    }

    @Test("Given || logic, when one direction subsumed, then still deduplicates")
    func deduplicationOrLogicBothDirections() {
        let small: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        let large: [(TokenKind, String)] =
            small + [
                (.keyword, "var"), (.identifier, "b"),
                (.operatorToken, "="), (.integerLiteral, "2"),
            ]

        let tokensLargeA = makeTokens(large, file: "A.swift")
        let tokensLargeB = makeTokens(large, file: "B.swift")

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: tokensLargeA, normalizedTokens: tokensLargeA
            ),
            FileTokens(
                file: "B.swift", source: "",
                tokens: tokensLargeB, normalizedTokens: tokensLargeB
            ),
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
        #expect(results[0].tokenCount == 8)
    }

    @Test("Given offset >= check, when inner starts at same offset, then subsumed")
    func subsumptionInnerStartsAtSameOffset() {
        let base: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"),
        ]

        let extended: [(TokenKind, String)] =
            base + [
                (.identifier, "b"), (.operatorToken, "="),
                (.integerLiteral, "2"),
            ]

        let tokensA = makeTokens(extended, file: "A.swift")
        let tokensB = makeTokens(extended, file: "B.swift")

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

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
        #expect(results[0].tokenCount == 8)
    }

    @Test("Given lineCount endLine - startLine + 1, when + mutated, then wrong")
    func lineCountExactArithmetic() {
        let locA = { (line: Int) in
            SourceLocation(file: "A.swift", line: line, column: 1)
        }
        let locB = { (line: Int) in
            SourceLocation(file: "B.swift", line: line, column: 1)
        }

        let tokensA = [
            Token(kind: .keyword, text: "let", location: locA(1)),
            Token(kind: .identifier, text: "x", location: locA(2)),
            Token(kind: .operatorToken, text: "=", location: locA(3)),
            Token(kind: .integerLiteral, text: "1", location: locA(4)),
            Token(kind: .keyword, text: "var", location: locA(5)),
        ]

        let tokensB = [
            Token(kind: .keyword, text: "let", location: locB(10)),
            Token(kind: .identifier, text: "x", location: locB(11)),
            Token(kind: .operatorToken, text: "=", location: locB(12)),
            Token(kind: .integerLiteral, text: "1", location: locB(13)),
            Token(kind: .keyword, text: "var", location: locB(14)),
        ]

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

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results[0].lineCount == 5)
    }

    @Test("Given AND check, when only A subsumed, then not subsumed")
    func subsumptionAndLogicRequiresBothSubsumed() {
        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"),
        ]

        let fileATokens = makeTokens(
            shared + [(.identifier, "extra1"), (.operatorToken, "+")],
            file: "A.swift"
        )
        let fileBTokens = makeTokens(shared, file: "B.swift")
        let fileCTokens = makeTokens(
            shared + [(.identifier, "extra2"), (.operatorToken, "-")],
            file: "C.swift"
        )

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

        let detector = CloneDetector(minimumTokenCount: 5, minimumLineCount: 1)
        let results = detector.detect(files: files)

        let pairsInvolvingB = results.filter { group in
            group.fragments.contains { $0.file == "B.swift" }
        }

        #expect(pairsInvolvingB.count >= 1)
    }

    @Test("Given end computed with + not -, when mutated, then wrong subsumption")
    func subsumptionEndArithmeticExactValues() {
        let shared: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
        ]

        let extended: [(TokenKind, String)] =
            shared + [
                (.integerLiteral, "1"), (.keyword, "var"),
                (.identifier, "b"),
            ]

        let tokensA = makeTokens(extended, file: "A.swift")
        let tokensB = makeTokens(extended, file: "B.swift")

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

        let detector = CloneDetector(minimumTokenCount: 3, minimumLineCount: 1)
        let results = detector.detect(files: files)

        let maxToken = results.map(\.tokenCount).max() ?? 0
        #expect(maxToken == 6)
    }

    @Test("Given abs(a - b), when mutated to abs(a + b), then same-file overlap wrong")
    func overlapAbsSubtractionNotAddition() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
            (.integerLiteral, "1"),
        ]

        var tokensA: [Token] = []
        for idx in 0 ..< 4 {
            tokensA.append(
                Token(
                    kind: specs[idx].0, text: specs[idx].1,
                    location: SourceLocation(
                        file: "A.swift", line: 1 + idx, column: 1
                    )
                ))
        }
        for idx in 0 ..< 4 {
            tokensA.append(
                Token(
                    kind: specs[idx].0, text: specs[idx].1,
                    location: SourceLocation(
                        file: "A.swift", line: 10 + idx, column: 1
                    )
                ))
        }

        let files = [
            FileTokens(
                file: "A.swift", source: "",
                tokens: tokensA, normalizedTokens: tokensA
            )
        ]

        let detector = CloneDetector(minimumTokenCount: 4, minimumLineCount: 1)
        let results = detector.detect(files: files)

        #expect(results.count == 1)
    }

    @Test("Given <= check on ends, when inner end equals outer end, then subsumed")
    func subsumptionEndEquality() {
        let specs: [(TokenKind, String)] = [
            (.keyword, "let"), (.identifier, "a"), (.operatorToken, "="),
            (.integerLiteral, "1"), (.keyword, "var"), (.identifier, "b"),
            (.operatorToken, "="), (.integerLiteral, "2"),
        ]

        let tokensA = makeTokens(specs, file: "A.swift")
        let tokensB = makeTokens(specs, file: "B.swift")

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

        #expect(results.count == 1)
        #expect(results[0].tokenCount == 8)
    }
}
