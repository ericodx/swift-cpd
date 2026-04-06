import Testing

@testable import swift_cpd

@Suite("BagJaccardSimilarity")
struct BagJaccardSimilarityTests {

    @Test("Given two empty arrays, when calculating similarity, then returns 1.0")
    func emptyArrays() {
        let similarity = BagJaccardSimilarity.calculate([String](), [String]())

        #expect(similarity == 1.0)
    }

    @Test("Given two empty frequency dictionaries, when calculating similarity, then returns 1.0")
    func emptyFrequencyDictionaries() {
        let similarity = BagJaccardSimilarity.calculate([String: Int](), [String: Int]())

        #expect(similarity == 1.0)
    }

    @Test("Given identical arrays, when calculating similarity, then returns 1.0")
    func identicalArrays() {
        let elements = ["let", "x", "=", "1"]
        let similarity = BagJaccardSimilarity.calculate(elements, elements)

        #expect(similarity == 1.0)
    }

    @Test("Given one empty and one non-empty array, when calculating similarity, then returns 0.0")
    func oneEmptyOneNonEmpty() {
        let similarity = BagJaccardSimilarity.calculate(["x"], [String]())

        #expect(similarity == 0.0)
    }

    @Test("Given completely disjoint arrays, when calculating similarity, then returns 0.0")
    func disjointArrays() {
        let tokensA = ["let", "x"]
        let tokensB = ["var", "y"]
        let similarity = BagJaccardSimilarity.calculate(tokensA, tokensB)

        #expect(similarity == 0.0)
    }

    @Test("Given partially overlapping arrays, when calculating similarity, then returns value between 0 and 1")
    func partialOverlap() {
        let tokensA = ["let", "x", "=", "1"]
        let tokensB = ["let", "y", "=", "2"]
        let similarity = BagJaccardSimilarity.calculate(tokensA, tokensB)

        #expect(similarity > 0.0)
        #expect(similarity < 1.0)
    }

    @Test("Given arrays with repeated elements, when calculating similarity, then accounts for frequencies")
    func repeatedElements() {
        let tokensA = ["x", "x", "x"]
        let tokensB = ["x", "x"]
        let similarity = BagJaccardSimilarity.calculate(tokensA, tokensB)

        #expect(similarity == 2.0 / 3.0)
    }
}
