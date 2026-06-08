@testable import swift_cpd

func makeSourceRefPipeline(
    cacheDir: String,
    reader: any SourceReader = WorkingTreeSourceReader(),
    resolvedSha: String? = nil
) -> AnalysisPipeline {
    AnalysisPipeline(
        detection: .init(minimumTokenCount: 10, minimumLineCount: 2),
        cache: .init(directory: cacheDir),
        source: .init(reader: reader, resolvedSha: resolvedSha)
    )
}
