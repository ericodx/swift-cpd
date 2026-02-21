struct Configuration: Sendable {

    let paths: [String]
    let minimumTokenCount: Int
    let minimumLineCount: Int
    let outputFormat: OutputFormat
    let outputFilePath: String?
    let baselineMode: BaselineMode
    let baselineFilePath: String
    let maxDuplication: Double?
    let type3Similarity: Int
    let type3TileSize: Int
    let type3CandidateThreshold: Int
    let type4Similarity: Int
    let crossLanguageEnabled: Bool
    let excludePatterns: [String]
    let inlineSuppressionTag: String
    let enabledCloneTypes: Set<CloneType>
    let ignoreSameFile: Bool
    let ignoreStructural: Bool
    let cacheDirectory: String
}

extension Configuration {

    init(from parsed: ParsedArguments, yaml: YamlConfiguration? = nil) throws {
        let mergedPaths = !parsed.paths.isEmpty ? parsed.paths : (yaml?.paths ?? [])

        guard
            !mergedPaths.isEmpty
        else {
            throw ConfigurationError.noPathsSpecified
        }

        self.paths = mergedPaths
        self.minimumTokenCount = parsed.minimumTokenCount ?? yaml?.minimumTokenCount ?? 50
        self.minimumLineCount = parsed.minimumLineCount ?? yaml?.minimumLineCount ?? 5
        self.outputFilePath = parsed.outputFilePath
        self.baselineFilePath = parsed.baselineFilePath ?? ".swiftcpd-baseline.json"
        self.maxDuplication = parsed.maxDuplication ?? yaml?.maxDuplication
        self.type3Similarity = parsed.type3Similarity ?? yaml?.type3Similarity ?? 70
        self.type3TileSize = parsed.type3TileSize ?? yaml?.type3TileSize ?? 5
        self.type3CandidateThreshold = parsed.type3CandidateThreshold ?? yaml?.type3CandidateThreshold ?? 30
        self.type4Similarity = parsed.type4Similarity ?? yaml?.type4Similarity ?? 80
        self.crossLanguageEnabled = parsed.crossLanguageEnabled || yaml?.crossLanguageEnabled ?? false
        self.excludePatterns = parsed.excludePatterns + (yaml?.exclude ?? [])
        self.inlineSuppressionTag = parsed.inlineSuppressionTag ?? yaml?.inlineSuppressionTag ?? "swiftcpd:ignore"
        self.ignoreSameFile = parsed.ignoreSameFile || yaml?.ignoreSameFile ?? false
        self.ignoreStructural = parsed.ignoreStructural || yaml?.ignoreStructural ?? false
        self.cacheDirectory = parsed.cacheDirectory ?? ".swiftcpd-cache"

        let yamlTypes = yaml?.enabledCloneTypes.map { Set($0.compactMap { CloneType(rawValue: $0) }) }
        self.enabledCloneTypes = parsed.enabledCloneTypes ?? yamlTypes ?? Set(CloneType.allCases)

        let yamlFormat = yaml?.outputFormat.flatMap { OutputFormat(rawValue: $0) }
        self.outputFormat = parsed.format ?? yamlFormat ?? .text

        if parsed.baselineGenerate {
            self.baselineMode = .generate
        } else if parsed.baselineUpdate {
            self.baselineMode = .update
        } else if parsed.baselineFilePath != nil {
            self.baselineMode = .compare
        } else {
            self.baselineMode = .none
        }

        try validate()
    }
}

extension Configuration {

    private func validate() throws {
        try validateRange("minimumTokenCount", minimumTokenCount, 10 ... 500)
        try validateRange("minimumLineCount", minimumLineCount, 2 ... 100)
        try validateRange("type3Similarity", type3Similarity, 50 ... 100)
        try validateRange("type3TileSize", type3TileSize, 2 ... 20)
        try validateRange("type3CandidateThreshold", type3CandidateThreshold, 10 ... 80)
        try validateRange("type4Similarity", type4Similarity, 60 ... 100)
    }

    private func validateRange(
        _ name: String,
        _ value: Int,
        _ range: ClosedRange<Int>
    ) throws {
        guard
            range.contains(value)
        else {
            throw ConfigurationError.parameterOutOfRange(
                name: name,
                value: value,
                validRange: range
            )
        }
    }
}
