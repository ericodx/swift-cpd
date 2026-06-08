extension AnalysisPipeline {

    struct SourceOptions: Sendable {

        init(
            reader: any SourceReader = WorkingTreeSourceReader(),
            resolvedSha: String? = nil
        ) {
            self.reader = reader
            self.resolvedSha = resolvedSha
        }

        var reader: any SourceReader
        var resolvedSha: String?
    }
}
