import Testing

@testable import swift_cpd

@Suite("LCSCalculator")
struct LCSCalculatorTests {

    @Test("Given one empty sequence, when calculating length, then returns 0")
    func oneEmptySequence() {
        let result = LCSCalculator.length(["a", "b"], [String]())

        #expect(result == 0)
    }

    @Test("Given both empty sequences, when calculating length, then returns 0")
    func bothEmptySequences() {
        let result = LCSCalculator.length([Int](), [Int]())

        #expect(result == 0)
    }

    @Test("Given identical sequences, when calculating length, then returns full length")
    func identicalSequences() {
        let result = LCSCalculator.length([1, 2, 3], [1, 2, 3])

        #expect(result == 3)
    }

    @Test("Given partially overlapping sequences, when calculating length, then returns correct LCS length")
    func partialOverlap() {
        let result = LCSCalculator.length([1, 2, 3, 4], [2, 4, 6])

        #expect(result == 2)
    }

    @Test("Given completely disjoint sequences, when calculating length, then returns 0")
    func completelyDisjoint() {
        let result = LCSCalculator.length([1, 2], [3, 4])

        #expect(result == 0)
    }

    @Test("Given both empty sequences, when calculating similarity, then returns 1.0")
    func bothEmptySimilarity() {
        let result = LCSCalculator.similarity([Int](), [Int]())

        #expect(result == 1.0)
    }

    @Test("Given one empty and one non-empty sequence, when calculating similarity, then returns 0.0")
    func oneEmptySimilarity() {
        let result = LCSCalculator.similarity(["a"], [String]())

        #expect(result == 0.0)
    }

    @Test("Given identical sequences, when calculating similarity, then returns 1.0")
    func identicalSimilarity() {
        let result = LCSCalculator.similarity([1, 2, 3], [1, 2, 3])

        #expect(result == 1.0)
    }
}
