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
        BagJaccardSimilarity.calculate(tokenFrequencies, other.tokenFrequencies)
    }
}
