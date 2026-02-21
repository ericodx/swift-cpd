struct BlockFingerprint: Sendable, Equatable {

    init(tokens: [Token], startIndex: Int, endIndex: Int) {
        var frequencies: [String: Int] = [:]

        for index in startIndex ... endIndex {
            let key = tokens[index].text
            frequencies[key, default: 0] += 1
        }

        self.tokenFrequencies = frequencies
    }

    let tokenFrequencies: [String: Int]
}

extension BlockFingerprint {

    func jaccardSimilarity(with other: BlockFingerprint) -> Double {
        let keysA = Set(tokenFrequencies.keys)
        let keysB = Set(other.tokenFrequencies.keys)

        let union = keysA.union(keysB)

        var intersectionSum = 0
        var unionSum = 0

        for key in union {
            let countA = tokenFrequencies[key] ?? 0
            let countB = other.tokenFrequencies[key] ?? 0

            intersectionSum += min(countA, countB)
            unionSum += max(countA, countB)
        }

        return Double(intersectionSum) / Double(unionSum)
    }
}
