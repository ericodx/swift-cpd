enum BagJaccardSimilarity {

    static func calculate<T: Hashable>(_ elementsA: [T], _ elementsB: [T]) -> Double {
        guard
            !elementsA.isEmpty || !elementsB.isEmpty
        else {
            return 1.0
        }

        return calculate(frequencies(of: elementsA), frequencies(of: elementsB))
    }

    static func calculate<T: Hashable>(_ frequenciesA: [T: Int], _ frequenciesB: [T: Int]) -> Double {
        let allKeys = Set(frequenciesA.keys).union(frequenciesB.keys)

        guard
            !allKeys.isEmpty
        else {
            return 1.0
        }

        var intersectionSum = 0
        var unionSum = 0

        for key in allKeys {
            let countA = frequenciesA[key, default: 0]
            let countB = frequenciesB[key, default: 0]
            intersectionSum += min(countA, countB)
            unionSum += max(countA, countB)
        }

        return Double(intersectionSum) / Double(unionSum)
    }

    private static func frequencies<T: Hashable>(of elements: [T]) -> [T: Int] {
        var result: [T: Int] = [:]

        for element in elements {
            result[element, default: 0] += 1
        }

        return result
    }
}
