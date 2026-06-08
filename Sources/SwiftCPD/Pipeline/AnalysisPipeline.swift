import Foundation

struct AnalysisPipeline: Sendable {

    init(
        detection: DetectionOptions = DetectionOptions(),
        cache: CacheOptions = CacheOptions(directory: ".swift-cpd-cache"),
        source: SourceOptions = SourceOptions()
    ) {
        self.detection = detection
        self.cache = cache
        self.source = source
        self.suppressionScanner = SuppressionScanner(tag: detection.inlineSuppressionTag)
    }

    let detection: DetectionOptions
    let cache: CacheOptions
    let source: SourceOptions

    private let swiftTokenizer = SwiftTokenizer()
    private let cTokenizer = CTokenizer()
    private let unifiedMapper = UnifiedTokenMapper()
    private let normalizer = TokenNormalizer()
    private let suppressionScanner: SuppressionScanner
    private let hasher = FileHasher()

    struct DetectionOptions: Sendable {
        var minimumTokenCount: Int = 50
        var minimumLineCount: Int = 5
        var thresholds: DetectionThresholds = .defaults
        var enabledCloneTypes: Set<CloneType> = Set(CloneType.allCases)
        var crossLanguageEnabled: Bool = false
        var inlineSuppressionTag: String = "swiftcpd:ignore"
    }

    struct CacheOptions: Sendable {
        var directory: String
        var disabled: Bool = false
    }

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
                minimumTokenCount: detection.minimumTokenCount,
                minimumLineCount: detection.minimumLineCount
            ),
            Type3Detector(
                similarityThreshold: Double(detection.thresholds.type3Similarity),
                minimumTileSize: detection.thresholds.type3TileSize,
                minimumTokenCount: detection.minimumTokenCount,
                minimumLineCount: detection.minimumLineCount,
                candidateFilterThreshold: Double(detection.thresholds.type3CandidateThreshold)
            ),
            Type4Detector(
                semanticSimilarityThreshold: Double(detection.thresholds.type4Similarity),
                minimumTokenCount: detection.minimumTokenCount,
                minimumLineCount: detection.minimumLineCount
            ),
        ]

        return allDetectors.filter { detector in
            !detector.supportedCloneTypes.isDisjoint(with: detection.enabledCloneTypes)
        }
    }

    private func filterByEnabledTypes(_ clones: [CloneGroup]) -> [CloneGroup] {
        clones.filter { detection.enabledCloneTypes.contains($0.type) }
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
        let data = try source.reader.read(file: filePath)
        let contentHash = hasher.hash(data: data)

        guard
            let sourceText = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        let cacheKey = CacheKey(file: filePath, resolvedSha: source.resolvedSha)

        if let cached = await cache.lookup(key: cacheKey, contentHash: contentHash) {
            return FileTokens(
                file: filePath,
                source: sourceText,
                tokens: cached.tokens,
                normalizedTokens: cached.normalizedTokens
            )
        }

        let rawTokens =
            if filePath.hasSuffix(".swift") {
                swiftTokenizer.tokenize(source: sourceText, file: filePath)
            } else {
                cTokenizer.tokenize(source: sourceText, file: filePath)
            }

        let mappedTokens = detection.crossLanguageEnabled ? unifiedMapper.map(rawTokens) : rawTokens
        let suppressedLines = suppressionScanner.suppressedLines(in: sourceText)
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

        await cache.store(key: cacheKey, entry: entry)

        return FileTokens(
            file: filePath,
            source: sourceText,
            tokens: tokens,
            normalizedTokens: normalizedTokens
        )
    }
}
