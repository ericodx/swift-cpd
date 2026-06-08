struct FilesystemSourceFileLister: SourceFileLister {

    init(crossLanguageEnabled: Bool, excludePatterns: [String] = []) {
        self.discovery = SourceFileDiscovery(
            crossLanguageEnabled: crossLanguageEnabled,
            excludePatterns: excludePatterns
        )
    }

    private let discovery: SourceFileDiscovery

    func listFiles(in paths: [String]) throws -> [String] {
        try discovery.findSourceFiles(in: paths)
    }
}
