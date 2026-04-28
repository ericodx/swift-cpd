import Foundation

struct AnalysisPipeline: Sendable {

    struct CacheOptions: Sendable {
        var directory: String
        var disabled: Bool = false
    }

    init(
        minimumTokenCount: Int = 50,
        minimumLineCount: Int = 5,
        cache: CacheOptions = CacheOptions(directory: ".swift-cpd-cache"),
        crossLanguageEnabled: Bool = false,
        thresholds: DetectionThresholds = .defaults,
        inlineSuppressionTag: String = "swiftcpd:ignore",
        enabledCloneTypes: Set<CloneType> = Set(CloneType.allCases)
    ) {
        self.minimumTokenCount = minimumTokenCount
        self.minimumLineCount = minimumLineCount
        self.cache = cache
        self.crossLanguageEnabled = crossLanguageEnabled
        self.thresholds = thresholds
        self.suppressionScanner = SuppressionScanner(tag: inlineSuppressionTag)
        self.enabledCloneTypes = enabledCloneTypes
    }

    let minimumTokenCount: Int
    let minimumLineCount: Int
    let cache: CacheOptions
    let crossLanguageEnabled: Bool
    let thresholds: DetectionThresholds
    let enabledCloneTypes: Set<CloneType>

    private let swiftTokenizer = SwiftTokenizer()
    private let cTokenizer = CTokenizer()
    private let unifiedMapper = UnifiedTokenMapper()
    private let normalizer = TokenNormalizer()
    private let suppressionScanner: SuppressionScanner
    private let hasher = FileHasher()

    func analyze(files: [String]) async throws -> PipelineResult {
        let fileCache = FileCache()

        if !cache.disabled {
            await fileCache.load(from: cache.directory)
        }

        let fileTokens = try await processFiles(files, cache: fileCache)

        if !cache.disabled {
            await fileCache.save(to: cache.directory)
        }

        let totalTokens = fileTokens.reduce(0) { $0 + $1.tokens.count }
        let detectors = buildDetectors()
        var allClones: [CloneGroup] = []

        for detector in detectors {
            let detected = detector.detect(files: fileTokens)
            allClones += filterByEnabledTypes(detected)
        }

        let sortedClones = allClones.sorted {
            guard let lhs = $0.fragments.first, let rhs = $1.fragments.first else { return false }

            if $0.type.rawValue != $1.type.rawValue { return $0.type.rawValue < $1.type.rawValue }
            if lhs.file != rhs.file { return lhs.file < rhs.file }

            return lhs.startLine < rhs.startLine
        }

        return PipelineResult(
            cloneGroups: sortedClones,
            totalTokens: totalTokens
        )
    }
}

extension AnalysisPipeline {

    private func buildDetectors() -> [any DetectionAlgorithm] {
        let allDetectors: [any DetectionAlgorithm] = [
            CloneDetector(
                minimumTokenCount: minimumTokenCount,
                minimumLineCount: minimumLineCount
            ),
            Type3Detector(
                similarityThreshold: Double(thresholds.type3Similarity),
                minimumTileSize: thresholds.type3TileSize,
                minimumTokenCount: minimumTokenCount,
                minimumLineCount: minimumLineCount,
                candidateFilterThreshold: Double(thresholds.type3CandidateThreshold)
            ),
            Type4Detector(
                semanticSimilarityThreshold: Double(thresholds.type4Similarity),
                minimumTokenCount: minimumTokenCount,
                minimumLineCount: minimumLineCount
            ),
        ]

        return allDetectors.filter { detector in
            !detector.supportedCloneTypes.isDisjoint(with: enabledCloneTypes)
        }
    }

    private func filterByEnabledTypes(_ clones: [CloneGroup]) -> [CloneGroup] {
        clones.filter { enabledCloneTypes.contains($0.type) }
    }

    private func processFiles(_ files: [String], cache: FileCache) async throws -> [FileTokens] {
        try await withThrowingTaskGroup(of: FileTokens.self) { group in
            for file in files {
                group.addTask {
                    try await tokenizeFile(file, cache: cache)
                }
            }

            var results: [FileTokens] = []

            for try await result in group {
                results.append(result)
            }

            return results.sorted { $0.file < $1.file }
        }
    }

    private func tokenizeFile(_ filePath: String, cache: FileCache) async throws -> FileTokens {
        let contentHash = try hasher.hash(contentsOf: filePath)
        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        if let cached = await cache.lookup(file: filePath, contentHash: contentHash) {
            return FileTokens(
                file: filePath,
                source: source,
                tokens: cached.tokens,
                normalizedTokens: cached.normalizedTokens
            )
        }

        let rawTokens =
            if filePath.hasSuffix(".swift") {
                swiftTokenizer.tokenize(source: source, file: filePath)
            } else {
                cTokenizer.tokenize(source: source, file: filePath)
            }

        let mappedTokens = crossLanguageEnabled ? unifiedMapper.map(rawTokens) : rawTokens
        let suppressedLines = suppressionScanner.suppressedLines(in: source)
        var tokens = mappedTokens
        if !suppressedLines.isEmpty {
            tokens = mappedTokens.filter { !suppressedLines.contains($0.location.line) }
        }
        let normalizedTokens = normalizer.normalize(tokens)

        let entry = CacheEntry(
            contentHash: contentHash,
            tokens: tokens,
            normalizedTokens: normalizedTokens
        )

        await cache.store(file: filePath, entry: entry)

        return FileTokens(
            file: filePath,
            source: source,
            tokens: tokens,
            normalizedTokens: normalizedTokens
        )
    }
}
