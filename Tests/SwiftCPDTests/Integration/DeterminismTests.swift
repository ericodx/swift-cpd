import Foundation
import Testing

@testable import swift_cpd

@Suite("Determinism")
struct DeterminismTests {

    @Test(
        "Given same files, when analyzing multiple times, then clone groups are identical"
    )
    func repeatedAnalysisProducesSameResults() async throws {
        let tempDir = createTempDirectory(prefix: "Determinism")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let resultA = try await analyzeDirectory(tempDir, cacheLabel: "run-a")
        let resultB = try await analyzeDirectory(tempDir, cacheLabel: "run-b")

        #expect(resultA.cloneGroups.count == resultB.cloneGroups.count)
        #expect(resultA.totalTokens == resultB.totalTokens)
    }

    @Test(
        "Given same files in different order, when analyzing, then results are equal"
    )
    func orderIndependentResults() async throws {
        let tempDir = createTempDirectory(prefix: "Determinism")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])
        let reversed = Array(files.reversed())

        let cacheA = tempDir + "/.cache-order-a"
        let pipelineA = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheA
        )
        let resultA = try await pipelineA.analyze(files: files)

        let cacheB = tempDir + "/.cache-order-b"
        let pipelineB = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheB
        )
        let resultB = try await pipelineB.analyze(files: reversed)

        #expect(resultA == resultB)
    }

    @Test(
        "Given same analysis result, when reporting text multiple times, then output is identical"
    )
    func textReporterDeterminism() async throws {
        let tempDir = createTempDirectory(prefix: "Determinism")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "text")
        let reporter = TextReporter()

        let outputA = reporter.report(result)
        let outputB = reporter.report(result)

        #expect(outputA == outputB)
    }

    @Test(
        "Given same analysis result, when reporting json multiple times, then output is identical"
    )
    func jsonReporterDeterminism() async throws {
        let tempDir = createTempDirectory(prefix: "Determinism")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let result = try await analyzeDirectory(tempDir, cacheLabel: "json")
        let reporter = JsonReporter()

        let outputA = reporter.report(result)
        let outputB = reporter.report(result)

        let dataA = try #require(outputA.data(using: .utf8))
        let dataB = try #require(outputB.data(using: .utf8))

        let jsonA = try JSONSerialization.jsonObject(with: dataA) as? [String: Any]
        let jsonB = try JSONSerialization.jsonObject(with: dataB) as? [String: Any]

        let clonesA = jsonA?["clones"] as? [[String: Any]]
        let clonesB = jsonB?["clones"] as? [[String: Any]]

        #expect(clonesA?.count == clonesB?.count)

        let summaryA = jsonA?["summary"] as? [String: Any]
        let summaryB = jsonB?["summary"] as? [String: Any]
        #expect(
            summaryA?["totalClones"] as? Int == summaryB?["totalClones"] as? Int
        )
    }

    @Test(
        "Given pipeline with cache, when second run uses cache, then results match first run"
    )
    func cachedResultsMatchUncached() async throws {
        let tempDir = createTempDirectory(prefix: "Determinism")
        defer { removeTempDirectory(tempDir) }

        writeDuplicateFiles(in: tempDir)

        let cacheDir = tempDir + "/.swiftcpd-cache"

        let pipeline = AnalysisPipeline(
            minimumTokenCount: 5,
            minimumLineCount: 1,
            cacheDirectory: cacheDir
        )

        let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
        let files = try discovery.findSourceFiles(in: [tempDir])

        let firstRun = try await pipeline.analyze(files: files)
        let secondRun = try await pipeline.analyze(files: files)

        #expect(firstRun == secondRun)
    }
}
