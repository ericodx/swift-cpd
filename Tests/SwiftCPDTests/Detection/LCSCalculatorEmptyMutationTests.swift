import Testing

@testable import swift_cpd

@Suite("LCSCalculator Empty Guard")
struct LCSCalculatorEmptyMutationTests {

    @Test("Given first empty, then returns zero")
    func firstSequenceEmpty() {
        #expect(LCSCalculator.length([Int](), [1, 2, 3]) == 0)
    }

    @Test("Given second empty, then returns zero")
    func secondSequenceEmpty() {
        #expect(LCSCalculator.length([1, 2, 3], [Int]()) == 0)
    }

    @Test("Given single matching, then returns 1")
    func singleElementMatch() {
        #expect(LCSCalculator.length([42], [42]) == 1)
    }

    @Test("Given single in first, then guard passes")
    func singleElementFirstSequence() {
        #expect(LCSCalculator.length([1], [1, 2, 3]) == 1)
    }
}
