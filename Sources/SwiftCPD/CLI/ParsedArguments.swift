struct ParsedArguments: Sendable, Equatable {

    var paths: [String] = []
    var minimumTokenCount: Int?
    var minimumLineCount: Int?
    var format: OutputFormat?
    var outputFilePath: String?
    var showVersion: Bool = false
    var showHelp: Bool = false
    var showInit: Bool = false
    var baselineGenerate: Bool = false
    var baselineUpdate: Bool = false
    var baselineFilePath: String?
    var configFilePath: String?
    var maxDuplication: Double?
    var type3Similarity: Int?
    var type3TileSize: Int?
    var type3CandidateThreshold: Int?
    var type4Similarity: Int?
    var crossLanguageEnabled: Bool = false
    var ignoreSameFile: Bool = false
    var ignoreStructural: Bool = false
    var excludePatterns: [String] = []
    var inlineSuppressionTag: String?
    var enabledCloneTypes: Set<CloneType>?
    var cacheDirectory: String?
}
