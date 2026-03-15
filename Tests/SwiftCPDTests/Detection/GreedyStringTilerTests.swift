import Testing

@testable import swift_cpd

@Suite("GreedyStringTiler")
struct GreedyStringTilerTests {

    private let tiler = GreedyStringTiler(minimumTileSize: 2)

    @Test("Given identical sequences, when computing similarity, then returns 1.0")
    func identicalSequences() {
        let tokens = makeSimpleTokens(["let", "x", "=", "1", "print", "x"])
        let similarity = tiler.similarity(between: tokens, and: tokens)

        #expect(similarity == 1.0)
    }

    @Test("Given completely different sequences, when computing similarity, then returns 0.0")
    func completelyDifferent() {
        let tokensA = makeSimpleTokens(["let", "x", "=", "1"])
        let tokensB = makeSimpleTokens(["func", "run", "(", ")"])

        let similarity = tiler.similarity(between: tokensA, and: tokensB)

        #expect(similarity == 0.0)
    }

    @Test("Given similar sequences with gap, when computing similarity, then returns value between 0 and 1")
    func similarWithGap() {
        let tokensA = makeSimpleTokens(["let", "x", "=", "1", "print", "x"])
        let tokensB = makeSimpleTokens(["let", "x", "=", "1", "return", "x"])

        let similarity = tiler.similarity(between: tokensA, and: tokensB)

        #expect(similarity > 0.0)
        #expect(similarity < 1.0)
    }

    @Test("Given empty sequences, when computing similarity, then returns 0.0")
    func emptySequences() {
        let similarity = tiler.similarity(between: [], and: [])

        #expect(similarity == 0.0)
    }

    @Test("Given one empty sequence, when computing similarity, then returns 0.0")
    func oneEmpty() {
        let tokens = makeSimpleTokens(["let", "x", "=", "1"])

        let similarity = tiler.similarity(between: tokens, and: [])

        #expect(similarity == 0.0)
    }

    @Test("Given sequence shorter than tile size, when computing similarity, then returns 0.0")
    func shorterThanTileSize() {
        let tiler = GreedyStringTiler(minimumTileSize: 5)
        let tokensA = makeSimpleTokens(["let", "x"])
        let tokensB = makeSimpleTokens(["let", "x"])

        let similarity = tiler.similarity(between: tokensA, and: tokensB)

        #expect(similarity == 0.0)
    }

    @Test("Given sequence with added tokens, when computing similarity, then detects shared structure")
    func addedTokens() {
        let tokensA = makeSimpleTokens(["func", "run", "{", "let", "x", "=", "1", "}"])
        let tokensB = makeSimpleTokens(["func", "run", "{", "let", "x", "=", "1", "print", "x", "}"])

        let similarity = tiler.similarity(between: tokensA, and: tokensB)

        #expect(similarity > 0.5)
    }

    @Test("Given similarity computation, when result calculated, then follows GST formula")
    func followsFormula() {
        let tokensA = makeSimpleTokens(["a", "b", "c", "d"])
        let tokensB = makeSimpleTokens(["a", "b", "x", "d"])
        let tiler = GreedyStringTiler(minimumTileSize: 2)

        let similarity = tiler.similarity(between: tokensA, and: tokensB)

        let expectedCovered = 2
        let expected = (2.0 * Double(expectedCovered)) / Double(tokensA.count + tokensB.count)
        #expect(similarity == expected)
    }
}
