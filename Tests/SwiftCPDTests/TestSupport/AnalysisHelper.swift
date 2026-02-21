import Foundation

@testable import swift_cpd

func analyzeDirectory(
    _ directory: String,
    minimumTokenCount: Int = 5,
    minimumLineCount: Int = 1,
    cacheLabel: String = "default"
) async throws -> AnalysisResult {
    let discovery = SourceFileDiscovery(crossLanguageEnabled: false)
    let files = try discovery.findSourceFiles(in: [directory])
    let cacheDir = directory + "/.swiftcpd-cache-\(cacheLabel)"

    let pipeline = AnalysisPipeline(
        minimumTokenCount: minimumTokenCount,
        minimumLineCount: minimumLineCount,
        cacheDirectory: cacheDir
    )

    let pipelineResult = try await pipeline.analyze(files: files)

    return AnalysisResult(
        cloneGroups: pipelineResult.cloneGroups,
        filesAnalyzed: files.count,
        executionTime: 0.0,
        totalTokens: pipelineResult.totalTokens,
        minimumTokenCount: minimumTokenCount,
        minimumLineCount: minimumLineCount
    )
}
