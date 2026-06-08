import Testing

@testable import swift_cpd

@Suite("Type3Detector Thresholds")
struct Type3DetectorThresholdsMutationTests {

    @Test("Given two blocks with similarity at threshold, when detecting with >=, then includes pair")
    func similarityExactlyAtThreshold() {
        let sourceA = """
            func processData() {
                let value = fetchValue()
                let result = transform(value)
                let output = format(result)
                save(output)
                log(output)
                validate(output)
                notify(output)
                cleanup()
                finalize()
            }
            """
        let sourceB = """
            func handleData() {
                let value = fetchValue()
                let result = transform(value)
                let output = format(result)
                save(output)
                log(output)
                validate(output)
                notify(output)
                cleanup()
                finalize()
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")
        let detector = Type3Detector(
            similarityThreshold: 50.0,
            minimumTileSize: 2,
            minimumTokenCount: 1,
            minimumLineCount: 1,
            candidateFilterThreshold: 10.0
        )

        let results = detector.detect(files: [fileA, fileB])

        #expect(!results.isEmpty)
    }

    @Test("Given two completely different blocks, when detecting, then returns no clones")
    func completelyDifferentBlocksReturnEmpty() {
        let sourceA = """
            func alpha() {
                let x = computeX()
                let y = computeY()
                let z = computeZ()
                saveAll(x, y, z)
                validateAll(x, y, z)
            }
            """
        let sourceB = """
            func beta() {
                for i in 0..<100 {
                    while condition(i) {
                        process(i)
                        update(i)
                        check(i)
                    }
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")
        let detector = Type3Detector(
            similarityThreshold: 95.0,
            minimumTileSize: 5,
            minimumTokenCount: 1,
            minimumLineCount: 1,
            candidateFilterThreshold: 90.0
        )

        let results = detector.detect(files: [fileA, fileB])

        #expect(results.isEmpty)
    }

    @Test("Given very different blocks, when >= used with high threshold, then rejected")
    func similarityBelowThresholdRejected() {
        let sourceA = """
            func processA() {
                let a1 = fetchAlpha()
                let a2 = transformAlpha(a1)
                let a3 = formatAlpha(a2)
                saveAlpha(a3)
                logAlpha(a3)
                validateAlpha(a3)
                cleanupAlpha(a3)
            }
            """
        let sourceB = """
            func processB() {
                for item in items {
                    while condition(item) {
                        handleBeta(item)
                        updateBeta(item)
                        checkBeta(item)
                        finalizeBeta(item)
                        reportBeta(item)
                    }
                }
            }
            """

        let fileA = makeFileTokens(source: sourceA, file: "A.swift")
        let fileB = makeFileTokens(source: sourceB, file: "B.swift")
        let detector = Type3Detector(
            similarityThreshold: 95.0,
            minimumTileSize: 3,
            minimumTokenCount: 1,
            minimumLineCount: 1,
            candidateFilterThreshold: 90.0
        )

        let results = detector.detect(files: [fileA, fileB])

        #expect(results.isEmpty)
    }
}
