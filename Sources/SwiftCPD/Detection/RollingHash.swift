struct RollingHash: Sendable {

    private let base: UInt64 = 31
    private let modulus: UInt64 = 1_000_000_007

    func hash(_ tokens: [Token], offset: Int, count: Int) -> UInt64 {
        var result: UInt64 = 0

        for index in offset ..< (offset + count) {
            result = (result &* base &+ tokenHash(tokens[index])) % modulus
        }

        return result
    }

    func rollingUpdate(
        hash: UInt64,
        removing: Token,
        adding: Token,
        highestPower: UInt64
    ) -> UInt64 {
        var result = hash
        let removeValue = (tokenHash(removing) &* highestPower) % modulus

        if result >= removeValue {
            result -= removeValue
        } else {
            result = modulus - (removeValue - result)
        }

        result = (result &* base &+ tokenHash(adding)) % modulus
        return result
    }

    func power(for windowSize: Int) -> UInt64 {
        var result: UInt64 = 1

        for _ in 0 ..< (windowSize - 1) {
            result = (result &* base) % modulus
        }

        return result
    }
}

extension RollingHash {

    private func tokenHash(_ token: Token) -> UInt64 {
        var result: UInt64 = 5381

        for byte in token.text.utf8 {
            result = ((result &<< 5) &+ result) &+ UInt64(byte)
        }

        return result % modulus
    }
}
