import Testing

@testable import swift_cpd

@Suite("DuplicationCalculator")
struct DuplicationCalculatorTests {

    @Test("Given zero total tokens, when calculating percentage, then returns zero")
    func zeroTotalTokensReturnsZero() {
        let result = DuplicationCalculator.percentage(duplicatedTokens: 0, totalTokens: 0)

        #expect(result == 0.0)
    }

    @Test("Given half duplicated tokens, when calculating percentage, then returns 50")
    func halfDuplicatedTokens() {
        let result = DuplicationCalculator.percentage(duplicatedTokens: 50, totalTokens: 100)

        #expect(result == 50.0)
    }

    @Test("Given all duplicated tokens, when calculating percentage, then returns 100")
    func allDuplicated() {
        let result = DuplicationCalculator.percentage(duplicatedTokens: 100, totalTokens: 100)

        #expect(result == 100.0)
    }
}
