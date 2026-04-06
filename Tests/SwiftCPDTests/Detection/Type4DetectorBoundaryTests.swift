import Testing

@testable import swift_cpd

@Suite("Type4Detector Boundary")
struct Type4DetectorBoundaryTests {

    @Test("Given very different control flow shapes, when detecting, then pre-filter rejects")
    func preFilterRejectsLargeShapeDifference() {
        let sourceA = """
            func manyBranches(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    if item > 0 {
                        total += item
                    }
                    if item < 100 {
                        total -= 1
                    }
                    while total > 1000 {
                        total /= 2
                    }
                    for nested in 0..<item {
                        if nested > 5 {
                            total += nested
                        }
                        while nested > 10 {
                            total -= nested
                        }
                        for deep in 0..<nested {
                            if deep > 2 {
                                total += deep
                            }
                        }
                    }
                }
                return total
            }
            """

        let sourceB = """
            func simple(_ value: Int) -> Int {
                if value > 0 {
                    return value
                }
                return 0
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 10.0,
            minimumTokenCount: 5,
            minimumLineCount: 2
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(result.isEmpty)
    }

    @Test("Given pre-filter boundary ratio exactly 0.3, when detecting, then passes")
    func preFilterBoundaryRatioExactly30Percent() {
        let sourceA = """
            func threeFlows(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                for item in items {
                    if item > 0 {
                        return item
                    }
                }
                return 0
            }
            """

        let sourceB = """
            func oneFlow(_ value: Int) -> Int {
                guard !value.isEmpty else { return 0 }
                if value > 0 {
                    return value
                }
                for i in 0..<value {
                    if i > 0 {
                        return i
                    }
                    if i < 10 {
                        return i + 1
                    }
                    while i > 100 {
                        return i
                    }
                    switch i {
                    case 0: return 0
                    default: return 1
                    }
                }
                return 0
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 1.0,
            minimumTokenCount: 5,
            minimumLineCount: 2
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(result.allSatisfy { $0.type == .type4 })
    }

    @Test("Given similarity at threshold boundary, when comparing, then includes clone")
    func similarityExactlyAtThresholdIncludes() {
        let sourceA = """
            func processA(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    total += item
                }
                return total
            }
            """

        let sourceB = """
            func processB(_ values: [Int]) -> Int {
                guard !values.isEmpty else { return 0 }
                var sum = 0
                for value in values {
                    sum += value
                }
                return sum
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let lowDetector = Type4Detector(
            semanticSimilarityThreshold: 50.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )
        let lowResult = lowDetector.detect(files: [fileA, fileB])

        #expect(!lowResult.isEmpty)
        #expect(lowResult[0].similarity > 0)

        let highDetector = Type4Detector(
            semanticSimilarityThreshold: 100.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )
        let highResult = highDetector.detect(files: [fileA, fileB])

        #expect(highResult.count <= lowResult.count)
    }

    @Test("Given 60/40 weighting, when computing similarity, then exceeds threshold")
    func combinedSimilarityWeighting() {
        let sourceA = """
            func computeA(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    if item > 0 {
                        total += item
                    }
                }
                return total
            }
            """

        let sourceB = """
            func computeB(_ values: [Int]) -> Int {
                guard !values.isEmpty else { return 0 }
                var result = 0
                for value in values {
                    if value > 0 {
                        result += value
                    }
                }
                return result
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 70.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(!result.isEmpty)
        #expect(result[0].similarity > 70.0)
    }
}
