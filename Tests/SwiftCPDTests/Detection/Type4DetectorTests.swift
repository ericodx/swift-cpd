import Testing

@testable import swift_cpd

@Suite("Type4Detector")
struct Type4DetectorTests {

    @Test("Given semantically similar functions, when detecting, then returns Type-4 clone")
    func detectsSemanticClones() {
        let sourceA = """
            func sumItems(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    total += item
                }
                return total
            }
            """

        let sourceB = """
            func computeTotal(_ values: [Int]) -> Int {
                guard !values.isEmpty else { return 0 }
                var result = 0
                for value in values {
                    result += value
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
        #expect(result.first?.type == .type4)
    }

    @Test("Given completely different functions, when detecting, then returns no clones")
    func noFalsePositives() {
        let sourceA = """
            func sortItems(_ items: [String]) -> [String] {
                return items.sorted()
            }
            """

        let sourceB = """
            func validate(_ input: Int) -> Bool {
                guard input > 0 else { return false }
                if input > 100 {
                    return false
                }
                return true
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 80.0,
            minimumTokenCount: 5,
            minimumLineCount: 2
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(result.isEmpty)
    }

    @Test("Given clones below threshold, when detecting, then filters them out")
    func respectsThreshold() {
        let sourceA = """
            func processA(_ items: [Int]) -> Int {
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
            func processB(_ values: [String]) -> String {
                switch values.count {
                case 0:
                    return ""
                default:
                    let joined = values.joined(separator: ", ")
                    return joined
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 90.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(result.isEmpty)
    }

    @Test("Given single file with one function, when detecting, then returns no clones")
    func singleBlockNoClones() {
        let source = """
            func doSomething(_ value: Int) -> Int {
                guard value > 0 else { return 0 }
                return value * 2
            }
            """

        let file = makeFileTokens(source: source, file: "A.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 70.0,
            minimumTokenCount: 5,
            minimumLineCount: 2
        )

        let result = detector.detect(files: [file])

        #expect(result.isEmpty)
    }

    @Test("Given clone result, when checking type, then type is type4")
    func cloneTypeIsType4() {
        let sourceA = """
            func filterPositive(_ items: [Int]) -> [Int] {
                guard !items.isEmpty else { return [] }
                var result: [Int] = []
                for item in items {
                    if item > 0 {
                        result.append(item)
                    }
                }
                return result
            }
            """

        let sourceB = """
            func filterNonEmpty(_ strings: [Int]) -> [Int] {
                guard !strings.isEmpty else { return [] }
                var filtered: [Int] = []
                for string in strings {
                    if string > 0 {
                        filtered.append(string)
                    }
                }
                return filtered
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

        guard
            let clone = result.first
        else {
            Issue.record("Expected at least one clone")
            return
        }

        #expect(clone.type == .type4)
        #expect(clone.similarity > 0)
        #expect(clone.fragments.count == 2)
    }

    @Test("Given functions with guard vs if-not-return, when detecting, then returns Type-4 clone")
    func detectsGuardVsIfNotReturn() {
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
                if values.isEmpty {
                    return 0
                }
                var sum = 0
                for value in values {
                    sum += value
                }
                return sum
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 60.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(!result.isEmpty)
        #expect(result.first?.type == .type4)
    }

    @Test("Given functions with for-in vs forEach, when detecting, then returns Type-4 clone")
    func detectsForInVsForEach() {
        let sourceA = """
            func printAllA(_ items: [String]) {
                for item in items {
                    if !item.isEmpty {
                        print(item)
                    }
                }
            }
            """

        let sourceB = """
            func printAllB(_ values: [String]) {
                values.forEach { value in
                    if !value.isEmpty {
                        print(value)
                    }
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 60.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(!result.isEmpty)
        #expect(result.first?.type == .type4)
    }

    @Test("Given functions with different names but same structure, when detecting, then returns Type-4 clone")
    func detectsDifferentNamessSameStructure() {
        let sourceA = """
            func calculateSum(_ numbers: [Int]) -> Int {
                guard !numbers.isEmpty else { return 0 }
                var accumulator = 0
                for number in numbers {
                    if number > 0 {
                        accumulator += number
                    }
                }
                return accumulator
            }
            """

        let sourceB = """
            func computeTotal(_ values: [Int]) -> Int {
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
        #expect(result.first?.type == .type4)
    }

    @Test("Given functions with no control flow, when detecting, then passes pre-filter")
    func noControlFlowPassesPreFilter() {
        let sourceA = """
            func computeA(_ value: Int) {
                let step1 = value * 2
                let step2 = step1 + 10
                let step3 = step2 - 5
                let step4 = step3 * 3
                let step5 = step4 / 2
                let step6 = step5 + 7
                print(step6)
            }
            """

        let sourceB = """
            func computeB(_ input: Int) {
                let phase1 = input * 3
                let phase2 = phase1 + 20
                let phase3 = phase2 - 8
                let phase4 = phase3 * 2
                let phase5 = phase4 / 3
                let phase6 = phase5 + 4
                print(phase6)
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let detector = Type4Detector(
            semanticSimilarityThreshold: 50.0,
            minimumTokenCount: 5,
            minimumLineCount: 3
        )

        let result = detector.detect(files: [fileA, fileB])

        #expect(!result.isEmpty)
    }

}
