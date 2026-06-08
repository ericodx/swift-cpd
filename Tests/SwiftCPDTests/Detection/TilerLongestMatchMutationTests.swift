import Testing

@testable import swift_cpd

@Suite("GreedyStringTiler Longest Match")
struct TilerLongestMatchMutationTests {

    @Test("Given longer match, when tiling, then replaces matches")
    func longerMatchReplacesExisting() {
        let tiler = GreedyStringTiler(minimumTileSize: 2)
        let tokA = makeSimpleTokens(["a", "b", "c", "x", "y"])
        let tokB = makeSimpleTokens(["z", "w", "a", "b", "c"])

        let similarity = tiler.similarity(between: tokA, and: tokB)

        let covered = 3
        let expected =
            (2.0 * Double(covered))
            / Double(tokA.count + tokB.count)
        #expect(similarity == expected)
    }

    @Test("Given equal match, when tiling, then appends")
    func equalMatchAppended() {
        let tiler = GreedyStringTiler(minimumTileSize: 2)
        let tokA = makeSimpleTokens(["a", "b", "x", "c", "d"])
        let tokB = makeSimpleTokens(["a", "b", "y", "c", "d"])

        let similarity = tiler.similarity(between: tokA, and: tokB)

        let covered = 4
        let expected =
            (2.0 * Double(covered))
            / Double(tokA.count + tokB.count)
        #expect(similarity == expected)
    }

    @Test("Given match at minimumTileSize, then matched but not longest")
    func matchAtMinimumTileSizeBoundary() {
        let tiler = GreedyStringTiler(minimumTileSize: 3)
        let tokA = makeSimpleTokens(["a", "b", "c", "x"])
        let tokB = makeSimpleTokens(["a", "b", "c", "y"])

        let similarity = tiler.similarity(between: tokA, and: tokB)
        #expect(similarity > 0)

        let tilerStrict = GreedyStringTiler(minimumTileSize: 4)
        let simStrict = tilerStrict.similarity(between: tokA, and: tokB)
        #expect(simStrict == 0)
    }

    @Test("Given > minimumTileSize, when mutated to >=, then changes")
    func longestMatchStrictGreaterThan() {
        let tiler = GreedyStringTiler(minimumTileSize: 3)
        let tokA = makeSimpleTokens(["a", "b", "c", "d", "e", "x"])
        let tokB = makeSimpleTokens(["a", "b", "c", "d", "e", "y"])

        let similarity = tiler.similarity(between: tokA, and: tokB)

        let covered = 5
        let expected =
            (2.0 * Double(covered))
            / Double(tokA.count + tokB.count)
        #expect(similarity == expected)
    }
}
