import Testing

@testable import swift_cpd

@Suite("RollingHash Underflow Guard")
struct RollingHashUnderflowMutationTests {

    @Test("Given result equals removeValue, then handles boundary")
    func resultEqualsRemoveValue() {
        let roller = RollingHash()
        let tokens = makeSimpleTokens(["a", "b", "c", "d"])
        let windowSize = 2
        let highestPower = roller.power(for: windowSize)

        let initialHash = roller.hash(
            tokens, offset: 0, count: windowSize
        )
        let updated = roller.rollingUpdate(
            hash: initialHash, removing: tokens[0],
            adding: tokens[2], highestPower: highestPower
        )
        let expected = roller.hash(
            tokens, offset: 1, count: windowSize
        )

        #expect(updated == expected)
    }

    @Test("Given chained updates, then all match recomputation")
    func chainedUpdatesAllMatch() {
        let roller = RollingHash()
        let tokens = makeSimpleTokens([
            "alpha", "beta", "gamma", "delta", "epsilon",
        ])
        let windowSize = 3
        let highestPower = roller.power(for: windowSize)

        var current = roller.hash(
            tokens, offset: 0, count: windowSize
        )

        for offset in 1 ... (tokens.count - windowSize) {
            current = roller.rollingUpdate(
                hash: current, removing: tokens[offset - 1],
                adding: tokens[offset + windowSize - 1],
                highestPower: highestPower
            )
            let expected = roller.hash(
                tokens, offset: offset, count: windowSize
            )

            #expect(current == expected)
        }
    }

    @Test("Given result >= removeValue, when >= mutated to >, then breaks")
    func rollingHashBoundaryEqualCase() {
        let roller = RollingHash()
        let tokens = makeSimpleTokens(["x", "x", "x"])
        let windowSize = 2
        let highestPower = roller.power(for: windowSize)

        let initialHash = roller.hash(
            tokens, offset: 0, count: windowSize
        )
        let updated = roller.rollingUpdate(
            hash: initialHash, removing: tokens[0],
            adding: tokens[2], highestPower: highestPower
        )
        let expected = roller.hash(
            tokens, offset: 1, count: windowSize
        )

        #expect(updated == expected)
    }
}
