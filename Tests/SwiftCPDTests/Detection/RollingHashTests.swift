import Testing

@testable import swift_cpd

@Suite("RollingHash")
struct RollingHashTests {

    private let rollingHash = RollingHash()
    private let location = SourceLocation(file: "test.swift", line: 1, column: 1)

    @Test("Given same tokens, when hashing twice, then produces identical hash")
    func deterministic() {
        let tokens = [
            Token(kind: .keyword, text: "let", location: location),
            Token(kind: .identifier, text: "x", location: location),
            Token(kind: .operatorToken, text: "=", location: location),
        ]

        let hashA = rollingHash.hash(tokens, offset: 0, count: 3)
        let hashB = rollingHash.hash(tokens, offset: 0, count: 3)

        #expect(hashA == hashB)
    }

    @Test("Given different tokens, when hashing, then produces different hashes")
    func differentInput() {
        let tokensA = [
            Token(kind: .keyword, text: "let", location: location),
            Token(kind: .identifier, text: "x", location: location),
            Token(kind: .operatorToken, text: "=", location: location),
        ]

        let tokensB = [
            Token(kind: .keyword, text: "var", location: location),
            Token(kind: .identifier, text: "y", location: location),
            Token(kind: .operatorToken, text: "+", location: location),
        ]

        let hashA = rollingHash.hash(tokensA, offset: 0, count: 3)
        let hashB = rollingHash.hash(tokensB, offset: 0, count: 3)

        #expect(hashA != hashB)
    }

    @Test("Given a sliding window, when using rolling update, then matches full recomputation")
    func rollingUpdateMatchesFullHash() {
        let tokens = [
            Token(kind: .keyword, text: "let", location: location),
            Token(kind: .identifier, text: "x", location: location),
            Token(kind: .operatorToken, text: "=", location: location),
            Token(kind: .integerLiteral, text: "42", location: location),
        ]

        let windowSize = 3
        let highestPower = rollingHash.power(for: windowSize)

        let initialHash = rollingHash.hash(tokens, offset: 0, count: windowSize)
        let rolledHash = rollingHash.rollingUpdate(
            hash: initialHash,
            removing: tokens[0],
            adding: tokens[3],
            highestPower: highestPower
        )

        let recomputedHash = rollingHash.hash(tokens, offset: 1, count: windowSize)

        #expect(rolledHash == recomputedHash)
    }

    @Test("Given multiple rolling updates, when chaining, then each matches full recomputation")
    func multipleRollingUpdates() {
        let tokens = [
            Token(kind: .keyword, text: "func", location: location),
            Token(kind: .identifier, text: "greet", location: location),
            Token(kind: .punctuation, text: "(", location: location),
            Token(kind: .punctuation, text: ")", location: location),
            Token(kind: .punctuation, text: "{", location: location),
        ]

        let windowSize = 3
        let highestPower = rollingHash.power(for: windowSize)

        var currentHash = rollingHash.hash(tokens, offset: 0, count: windowSize)

        for offset in 1 ... (tokens.count - windowSize) {
            currentHash = rollingHash.rollingUpdate(
                hash: currentHash,
                removing: tokens[offset - 1],
                adding: tokens[offset + windowSize - 1],
                highestPower: highestPower
            )

            let expected = rollingHash.hash(tokens, offset: offset, count: windowSize)
            #expect(currentHash == expected)
        }
    }
}
