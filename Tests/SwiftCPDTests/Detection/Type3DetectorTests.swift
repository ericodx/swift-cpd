import Testing

@testable import swift_cpd

@Suite("Type3Detector")
struct Type3DetectorTests {

    @Test("Given similar functions with gap, when detecting, then returns Type-3 clone")
    func detectsSimilarFunctions() {
        let sourceA = """
            func validate(_ input: String) -> Bool {
                guard !input.isEmpty else { return false }
                guard input.count > 3 else { return false }
                return input.allSatisfy { $0.isLetter }
            }
            """

        let sourceB = """
            func check(_ value: String) -> Bool {
                guard !value.isEmpty else { return false }
                guard value.count > 5 else { return false }
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                return trimmed.allSatisfy { $0.isLetter }
            }
            """

        let files = [
            makeFileTokens(source: sourceA, file: "A.swift"),
            makeFileTokens(source: sourceB, file: "B.swift"),
        ]

        let detector = Type3Detector(
            similarityThreshold: 50.0,
            minimumTileSize: 3,
            minimumTokenCount: 5,
            minimumLineCount: 2,
            candidateFilterThreshold: 20.0
        )

        let results = detector.detect(files: files)

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.type == .type3 })
    }

    @Test("Given completely different functions, when detecting, then returns no clones")
    func noFalsePositives() {
        let sourceA = """
            func add(_ a: Int, _ b: Int) -> Int {
                return a + b
            }
            """

        let sourceB = """
            func greet(_ name: String) {
                print("Hello, " + name)
            }
            """

        let files = [
            makeFileTokens(source: sourceA, file: "A.swift"),
            makeFileTokens(source: sourceB, file: "B.swift"),
        ]

        let detector = Type3Detector(
            similarityThreshold: 70.0,
            minimumTileSize: 3,
            minimumTokenCount: 5,
            minimumLineCount: 2,
            candidateFilterThreshold: 20.0
        )

        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given clones below threshold, when detecting, then filters them out")
    func respectsThreshold() {
        let sourceA = """
            func processA(_ items: [Int]) -> [Int] {
                let filtered = items.filter { $0 > 0 }
                let mapped = filtered.map { $0 * 2 }
                return mapped.sorted()
            }
            """

        let sourceB = """
            func processB(_ data: [String]) -> [String] {
                let trimmed = data.map { $0.trimmingCharacters(in: .whitespaces) }
                let nonEmpty = trimmed.filter { !$0.isEmpty }
                return nonEmpty.reversed()
            }
            """

        let files = [
            makeFileTokens(source: sourceA, file: "A.swift"),
            makeFileTokens(source: sourceB, file: "B.swift"),
        ]

        let detector = Type3Detector(
            similarityThreshold: 95.0,
            minimumTileSize: 3,
            minimumTokenCount: 5,
            minimumLineCount: 2,
            candidateFilterThreshold: 10.0
        )

        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given single file, when detecting, then returns no clones")
    func singleFile() {
        let source = """
            func run() {
                let x = 1
                print(x)
            }
            """

        let files = [makeFileTokens(source: source, file: "A.swift")]

        let detector = Type3Detector(
            similarityThreshold: 70.0,
            minimumTileSize: 3,
            minimumTokenCount: 3,
            minimumLineCount: 1,
            candidateFilterThreshold: 20.0
        )

        let results = detector.detect(files: files)

        #expect(results.isEmpty)
    }

    @Test("Given clone result, when checking properties, then similarity is percentage")
    func similarityIsPercentage() {
        let sourceA = """
            func foo() -> Int {
                let a = 1
                let b = 2
                let c = 3
                return a + b + c
            }
            """

        let sourceB = """
            func bar() -> Int {
                let x = 1
                let y = 2
                let z = 3
                return x + y + z
            }
            """

        let files = [
            makeFileTokens(source: sourceA, file: "A.swift"),
            makeFileTokens(source: sourceB, file: "B.swift"),
        ]

        let detector = Type3Detector(
            similarityThreshold: 50.0,
            minimumTileSize: 2,
            minimumTokenCount: 5,
            minimumLineCount: 2,
            candidateFilterThreshold: 10.0
        )

        let results = detector.detect(files: files)

        for clone in results {
            #expect(clone.similarity > 0.0)
            #expect(clone.similarity <= 100.0)
        }
    }
}
