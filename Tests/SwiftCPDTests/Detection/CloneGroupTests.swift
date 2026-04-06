import Testing

@testable import swift_cpd

@Suite("CloneGroup")
struct CloneGroupTests {

    @Test("Given a clone group, when accessing fields, then returns stored values")
    func fieldStorage() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 20, endLine: 30, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type2, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(group.type == .type2)
        #expect(group.tokenCount == 50)
        #expect(group.lineCount == 10)
        #expect(group.similarity == 100.0)
        #expect(group.fragments.count == 2)
    }

    @Test("Given two identical groups, when comparing, then they are equal")
    func equality() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 5, startColumn: 1, endColumn: 2),
        ]

        let groupA = CloneGroup(type: .type1, tokenCount: 30, lineCount: 5, similarity: 100.0, fragments: fragments)
        let groupB = CloneGroup(type: .type1, tokenCount: 30, lineCount: 5, similarity: 100.0, fragments: fragments)

        #expect(groupA == groupB)
    }

    @Test("Given a Type-3 group, when accessing similarity, then returns partial similarity")
    func type3Similarity() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 15, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 10, endLine: 25, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type3, tokenCount: 80, lineCount: 15, similarity: 75.5, fragments: fragments)

        #expect(group.type == .type3)
        #expect(group.similarity == 75.5)
    }

    @Test("Given Type-3 group, when checking isStructural, then returns true")
    func type3IsStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type3, tokenCount: 50, lineCount: 10, similarity: 75.0, fragments: fragments)

        #expect(group.isStructural)
    }

    @Test("Given Type-4 group, when checking isStructural, then returns true")
    func type4IsStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type4, tokenCount: 50, lineCount: 10, similarity: 80.0, fragments: fragments)

        #expect(group.isStructural)
    }

    @Test("Given Type-1 group, when checking isStructural, then returns false")
    func type1IsNotStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isStructural)
    }

    @Test("Given Type-2 group, when checking isStructural, then returns false")
    func type2IsNotStructural() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type2, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isStructural)
    }

    @Test("Given fragments in same file, when checking isSameFile, then returns true")
    func sameFileFragments() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "A.swift", startLine: 20, endLine: 30, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(group.isSameFile)
    }

    @Test("Given fragments in different files, when checking isSameFile, then returns false")
    func differentFileFragments() {
        let fragments = [
            CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
            CloneFragment(file: "B.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2),
        ]

        let group = CloneGroup(type: .type1, tokenCount: 50, lineCount: 10, similarity: 100.0, fragments: fragments)

        #expect(!group.isSameFile)
    }

    @Test("Given empty fragments, when checking isSameFile, then returns false")
    func emptyFragmentsIsSameFile() {
        let group = CloneGroup(type: .type1, tokenCount: 0, lineCount: 0, similarity: 100.0, fragments: [])

        #expect(!group.isSameFile)
    }

    @Test("Given a pair where lineCount equals minimumLineCount, when creating group, then returns non-nil")
    func lineCountEqualToMinimumReturnsGroup() {
        let tokens = makeTokens(
            [
                (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="), (.integerLiteral, "1"),
                (.keyword, "print"),
            ],
            file: "A.swift",
            startLine: 10
        )

        let fileTokens = FileTokens(file: "A.swift", source: "", tokens: tokens, normalizedTokens: tokens)

        let blockA = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 10, endLine: 14, startTokenIndex: 0, endTokenIndex: 4),
            fileIndex: 0
        )

        let blockB = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 10, endLine: 14, startTokenIndex: 0, endTokenIndex: 4),
            fileIndex: 0
        )

        let pair = IndexedBlockPair(blockA: blockA, blockB: blockB)

        let group = CloneGroup(type: .type1, pair: pair, files: [fileTokens], similarity: 1.0, minimumLineCount: 5)

        #expect(group != nil)
    }

    @Test("Given a pair where lineCount is below minimumLineCount, when creating group, then returns nil")
    func lineCountBelowMinimumReturnsNil() {
        let tokens = makeTokens(
            [(.keyword, "let"), (.identifier, "x"), (.operatorToken, "="), (.integerLiteral, "1")],
            file: "A.swift",
            startLine: 10
        )

        let fileTokens = FileTokens(file: "A.swift", source: "", tokens: tokens, normalizedTokens: tokens)

        let blockA = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 10, endLine: 13, startTokenIndex: 0, endTokenIndex: 3),
            fileIndex: 0
        )

        let blockB = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 10, endLine: 13, startTokenIndex: 0, endTokenIndex: 3),
            fileIndex: 0
        )

        let pair = IndexedBlockPair(blockA: blockA, blockB: blockB)

        let group = CloneGroup(type: .type1, pair: pair, files: [fileTokens], similarity: 1.0, minimumLineCount: 5)

        #expect(group == nil)
    }

    @Test("Given a valid pair, when creating group, then lineCount equals endLine minus startLine plus one")
    func lineCountCalculation() {
        let tokens = makeTokens(
            [
                (.keyword, "func"), (.identifier, "a"), (.punctuation, "("), (.punctuation, ")"),
                (.punctuation, "{"), (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="),
                (.integerLiteral, "1"), (.punctuation, "}"),
            ],
            file: "A.swift",
            startLine: 5
        )

        let fileTokens = FileTokens(file: "A.swift", source: "", tokens: tokens, normalizedTokens: tokens)

        let blockA = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 5, endLine: 14, startTokenIndex: 0, endTokenIndex: 9),
            fileIndex: 0
        )

        let blockB = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 5, endLine: 14, startTokenIndex: 0, endTokenIndex: 9),
            fileIndex: 0
        )

        let pair = IndexedBlockPair(blockA: blockA, blockB: blockB)

        let group = CloneGroup(type: .type1, pair: pair, files: [fileTokens], similarity: 1.0, minimumLineCount: 1)

        #expect(group != nil)
        #expect(group?.lineCount == 10)
    }

    @Test(
        "Given a valid pair, when creating group, then tokenCount equals endTokenIndex minus startTokenIndex plus one"
    )
    func tokenCountCalculation() {
        let tokens = makeTokens(
            [
                (.keyword, "let"), (.identifier, "x"), (.operatorToken, "="), (.integerLiteral, "42"),
                (.keyword, "let"), (.identifier, "y"), (.operatorToken, "="),
            ],
            file: "A.swift",
            startLine: 1
        )

        let fileTokens = FileTokens(file: "A.swift", source: "", tokens: tokens, normalizedTokens: tokens)

        let blockA = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 1, endLine: 7, startTokenIndex: 0, endTokenIndex: 6),
            fileIndex: 0
        )

        let blockB = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 1, endLine: 7, startTokenIndex: 0, endTokenIndex: 3),
            fileIndex: 0
        )

        let pair = IndexedBlockPair(blockA: blockA, blockB: blockB)

        let group = CloneGroup(type: .type1, pair: pair, files: [fileTokens], similarity: 1.0, minimumLineCount: 1)

        #expect(group != nil)
        #expect(group?.tokenCount == 7)
    }

    @Test("Given asymmetric blocks, when creating group, then lineCount uses the larger fragment")
    func lineCountUsesLargerFragment() {
        let tokensA = makeTokens(
            [(.keyword, "let"), (.identifier, "a"), (.operatorToken, "=")],
            file: "A.swift",
            startLine: 1
        )

        let tokensB = makeTokens(
            [
                (.keyword, "let"), (.identifier, "b"), (.operatorToken, "="), (.integerLiteral, "1"),
                (.keyword, "let"), (.identifier, "c"),
            ],
            file: "B.swift",
            startLine: 10
        )

        let fileTokensA = FileTokens(file: "A.swift", source: "", tokens: tokensA, normalizedTokens: tokensA)
        let fileTokensB = FileTokens(file: "B.swift", source: "", tokens: tokensB, normalizedTokens: tokensB)

        let blockA = IndexedBlock(
            block: CodeBlock(file: "A.swift", startLine: 1, endLine: 3, startTokenIndex: 0, endTokenIndex: 2),
            fileIndex: 0
        )

        let blockB = IndexedBlock(
            block: CodeBlock(file: "B.swift", startLine: 10, endLine: 15, startTokenIndex: 0, endTokenIndex: 5),
            fileIndex: 1
        )

        let pair = IndexedBlockPair(blockA: blockA, blockB: blockB)

        let group = CloneGroup(
            type: .type3, pair: pair, files: [fileTokensA, fileTokensB], similarity: 0.8, minimumLineCount: 1
        )

        #expect(group != nil)
        #expect(group?.lineCount == 6)
        #expect(group?.tokenCount == 6)
    }
}
