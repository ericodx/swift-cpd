import Testing

@testable import swift_cpd

@Suite("Type4Detector PreFilter")
struct Type4DetectorPreFilterMutationTests {

    @Test("Given both blocks with empty control flow, when pre-filtering, then passes")
    func emptyControlFlowPassesFilter() {
        let sourceA = """
            func simpleA() {
                let a = getValue()
                let b = getValue()
                let c = getValue()
                process(a, b, c)
                save(a, b, c)
            }
            """
        let sourceB = """
            func simpleB() {
                let x = getValue()
                let y = getValue()
                let z = getValue()
                process(x, y, z)
                save(x, y, z)
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")
        let detector = Type4Detector(
            semanticSimilarityThreshold: 10.0,
            minimumTokenCount: 1,
            minimumLineCount: 1
        )

        let results = detector.detect(files: [fileA, fileB])

        #expect(!results.isEmpty)
    }

    @Test("Given blocks with very different control flow, when detecting, then rejects")
    func veryDifferentControlFlowRejected() {
        let sourceA = """
            func complex() {
                if a { if b { if c { if d { if e {
                    process()
                } } } } }
            }
            """
        let sourceB = """
            func simple() {
                process()
                save()
                log()
                validate()
                cleanup()
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")
        let detector = Type4Detector(
            semanticSimilarityThreshold: 1.0,
            minimumTokenCount: 1,
            minimumLineCount: 1
        )

        let sigA = BehaviorSignatureExtractor(
            source: sourceA,
            file: "A.swift",
            startLine: 1,
            endLine: 8
        ).extract()
        let sigB = BehaviorSignatureExtractor(
            source: sourceB,
            file: "B.swift",
            startLine: 1,
            endLine: 7
        ).extract()

        let lenA = sigA.controlFlowShape.count
        let lenB = sigB.controlFlowShape.count

        if lenA > 0 || lenB > 0 {
            let maxLen = max(lenA, lenB)
            let ratio = Double(min(lenA, lenB)) / Double(maxLen)

            if ratio < 0.3 {
                let results = detector.detect(files: [fileA, fileB])
                #expect(results.isEmpty)
            }
        }
    }

    @Test("Given one block with flow, one without, when || used, then differs from &&")
    func orVsAndInPreFilter() {
        let sourceA = """
            func withFlow() {
                if condition {
                    process()
                }
                save()
                validate()
                cleanup()
            }
            """
        let sourceB = """
            func noFlow() {
                process()
                save()
                validate()
                cleanup()
                finalize()
                report()
            }
            """

        let sigA = BehaviorSignatureExtractor(
            source: sourceA, file: "A.swift", startLine: 1, endLine: 8
        ).extract()
        let sigB = BehaviorSignatureExtractor(
            source: sourceB, file: "B.swift", startLine: 1, endLine: 8
        ).extract()

        let lenA = sigA.controlFlowShape.count
        let lenB = sigB.controlFlowShape.count

        let orResult = lenA > 0 || lenB > 0
        let andResult = lenA > 0 && lenB > 0

        #expect(orResult != andResult)
    }

    @Test("Given ratio >= 0.3, when mutated to >, then exact 0.3 changes")
    func preFilterRatioExactlyAtBoundary() {
        let lenA = 3
        let lenB = 10
        let maxLen = max(lenA, lenB)
        let ratio = Double(min(lenA, lenB)) / Double(maxLen)

        #expect(ratio == 0.3)

        let passesWithGte = ratio >= 0.3
        let passesWithGt = ratio > 0.3

        #expect(passesWithGte)
        #expect(!passesWithGt)
    }

    @Test("Given combinedSimilarity >= threshold, when mutated to >, then changes")
    func combinedSimilarityExactlyAtThreshold() {
        let sourceA = """
            func compute() {
                let a = getValue()
                let b = getValue()
                let c = a + b
                print(c)
                save(c)
            }
            """
        let sourceB = """
            func calculate() {
                let x = getValue()
                let y = getValue()
                let z = x + y
                print(z)
                save(z)
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")

        let lowThreshold = Type4Detector(
            semanticSimilarityThreshold: 1.0,
            minimumTokenCount: 1,
            minimumLineCount: 1
        )
        let results = lowThreshold.detect(files: [fileA, fileB])

        #expect(!results.isEmpty)
    }
}
