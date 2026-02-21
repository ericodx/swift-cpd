enum LCSCalculator {

    static func length<T: Equatable>(_ sequenceA: [T], _ sequenceB: [T]) -> Int {
        let lengthA = sequenceA.count
        let lengthB = sequenceB.count

        guard
            lengthA > 0,
            lengthB > 0
        else {
            return 0
        }

        var previous = [Int](repeating: 0, count: lengthB + 1)
        var current = [Int](repeating: 0, count: lengthB + 1)

        for indexA in 1 ... lengthA {
            for indexB in 1 ... lengthB {
                if sequenceA[indexA - 1] == sequenceB[indexB - 1] {
                    current[indexB] = previous[indexB - 1] + 1
                } else {
                    current[indexB] = max(previous[indexB], current[indexB - 1])
                }
            }

            previous = current
            current = [Int](repeating: 0, count: lengthB + 1)
        }

        return previous[lengthB]
    }

    static func similarity<T: Equatable>(_ sequenceA: [T], _ sequenceB: [T]) -> Double {
        guard
            !sequenceA.isEmpty || !sequenceB.isEmpty
        else {
            return 1.0
        }

        let lcs = length(sequenceA, sequenceB)
        return Double(2 * lcs) / Double(sequenceA.count + sequenceB.count)
    }
}
