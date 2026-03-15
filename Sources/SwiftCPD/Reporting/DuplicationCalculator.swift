enum DuplicationCalculator {

    static func percentage(duplicatedTokens: Int, totalTokens: Int) -> Double {
        guard
            totalTokens > 0
        else {
            return 0.0
        }

        let raw = (Double(duplicatedTokens) / Double(totalTokens)) * 100.0
        return (raw * 10).rounded() / 10
    }
}
