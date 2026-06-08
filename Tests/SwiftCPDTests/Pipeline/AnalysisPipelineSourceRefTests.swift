import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline sourceRef")
struct AnalysisPipelineSourceRefTests {

    @Test("Given working-tree reader, when analyzing, then produces clones as before (P1)")
    func workingTreeRegression() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        try repo.commit()

        let cacheDir = repo.root + "/.swift-cpd-cache"
        let pipeline = makePipeline(cacheDir: cacheDir)
        let result = try await pipeline.analyze(files: [
            repo.root + "/Sources/A.swift",
            repo.root + "/Sources/B.swift",
        ])

        #expect(!result.cloneGroups.isEmpty)
    }

    @Test("Given duplication at HEAD that WT removed, when analyzing with sourceRef=HEAD, then reports the clone (P2)")
    func gitRefPipelineSeesBlobClones() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        let sha = try repo.commit()

        try repo.writeFile("Sources/A.swift", content: "// unrelated working-tree edit\n")
        try repo.writeFile("Sources/B.swift", content: "// unrelated working-tree edit\n")

        let cacheDir = repo.root + "/.swift-cpd-cache-ref"
        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)
        let pipeline = makePipeline(cacheDir: cacheDir, reader: reader, resolvedSha: sha)
        let files = try GitRefSourceFileLister(
            ref: "HEAD",
            resolvedSha: sha,
            repositoryRoot: repo.root,
            crossLanguageEnabled: false
        ).listFiles(in: ["Sources"])

        let result = try await pipeline.analyze(files: files)

        #expect(!result.cloneGroups.isEmpty)

        let cacheDirWT = repo.root + "/.swift-cpd-cache-wt"
        let wtPipeline = makePipeline(cacheDir: cacheDirWT)
        let wtResult = try await wtPipeline.analyze(files: files)

        #expect(wtResult.cloneGroups.isEmpty)
    }

    @Test("Given two runs with the same resolvedSha, when caching, then cache uses sha|path keys (P3)")
    func cacheKeysIncludeResolvedSha() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        let sha = try repo.commit()

        let cacheDir = repo.root + "/.swift-cpd-cache"
        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)
        let pipeline = makePipeline(cacheDir: cacheDir, reader: reader, resolvedSha: sha)
        let files = [repo.root + "/Sources/A.swift", repo.root + "/Sources/B.swift"]

        _ = try await pipeline.analyze(files: files)

        let envelope = try loadCacheEnvelope(at: cacheDir)
        #expect(envelope.schemaVersion == FileCache.currentSchemaVersion)
        #expect(envelope.entries.keys.contains { $0.hasPrefix("\(sha)|") })
        #expect(envelope.entries.keys.contains { $0.hasSuffix("/Sources/A.swift") })
    }

    @Test("Given a new commit changes content, when re-running, then a separate cache entry appears (P4)")
    func cacheMissOnDifferentSha() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        let firstSha = try repo.commit(message: "first")

        let cacheDir = repo.root + "/.swift-cpd-cache"
        let firstFiles = [repo.root + "/Sources/A.swift", repo.root + "/Sources/B.swift"]
        let firstPipeline = makePipeline(
            cacheDir: cacheDir,
            reader: GitRefSourceReader(
                ref: "HEAD", resolvedSha: firstSha, repositoryRoot: repo.root
            ),
            resolvedSha: firstSha
        )
        _ = try await firstPipeline.analyze(files: firstFiles)

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource + "\n// changed\n")
        let secondSha = try repo.commit(message: "second")
        #expect(firstSha != secondSha)

        let secondPipeline = makePipeline(
            cacheDir: cacheDir,
            reader: GitRefSourceReader(
                ref: "HEAD", resolvedSha: secondSha, repositoryRoot: repo.root
            ),
            resolvedSha: secondSha
        )
        _ = try await secondPipeline.analyze(files: firstFiles)

        let envelope = try loadCacheEnvelope(at: cacheDir)
        let firstShaKeys = envelope.entries.keys.filter { $0.hasPrefix("\(firstSha)|") }
        let secondShaKeys = envelope.entries.keys.filter { $0.hasPrefix("\(secondSha)|") }

        #expect(!firstShaKeys.isEmpty)
        #expect(!secondShaKeys.isEmpty)
    }

    @Test("Given a mutable ref that moves between runs, when caching, then resolved shas key separately (P5)")
    func mutableRefIsolatedByResolvedSha() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        let firstSha = try repo.commit(message: "first")

        let cacheDir = repo.root + "/.swift-cpd-cache"
        let firstResolved = try GitRefResolver().resolve(ref: "main", in: repo.root)
        #expect(firstResolved.resolvedSha == firstSha)

        let firstFiles = [repo.root + "/Sources/A.swift", repo.root + "/Sources/B.swift"]
        let firstPipeline = makePipeline(
            cacheDir: cacheDir,
            reader: GitRefSourceReader(
                ref: "main", resolvedSha: firstResolved.resolvedSha, repositoryRoot: repo.root
            ),
            resolvedSha: firstResolved.resolvedSha
        )
        _ = try await firstPipeline.analyze(files: firstFiles)

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource + "\n// v2\n")
        try repo.commit(message: "second")

        let secondResolved = try GitRefResolver().resolve(ref: "main", in: repo.root)
        #expect(secondResolved.resolvedSha != firstResolved.resolvedSha)

        let secondPipeline = makePipeline(
            cacheDir: cacheDir,
            reader: GitRefSourceReader(
                ref: "main", resolvedSha: secondResolved.resolvedSha, repositoryRoot: repo.root
            ),
            resolvedSha: secondResolved.resolvedSha
        )
        _ = try await secondPipeline.analyze(files: firstFiles)

        let envelope = try loadCacheEnvelope(at: cacheDir)
        let firstShaPresent = envelope.entries.keys.contains { $0.hasPrefix("\(firstResolved.resolvedSha)|") }
        let secondShaPresent = envelope.entries.keys.contains { $0.hasPrefix("\(secondResolved.resolvedSha)|") }
        let literalRefKey = envelope.entries.keys.contains { $0.hasPrefix("main|") }

        #expect(firstShaPresent)
        #expect(secondShaPresent)
        #expect(!literalRefKey)
    }

    @Test("Given suppression tag at HEAD but absent in WT, when analyzing at HEAD, then clone is suppressed (P6)")
    func suppressionRespectsRefContent() async throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "// swiftcpd:ignore\n" + standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: standardDuplicateSource)
        let sha = try repo.commit()

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)

        let files = [repo.root + "/Sources/A.swift", repo.root + "/Sources/B.swift"]

        let cacheDirRef = repo.root + "/.swift-cpd-cache-ref"
        let refPipeline = makePipeline(
            cacheDir: cacheDirRef,
            reader: GitRefSourceReader(
                ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root
            ),
            resolvedSha: sha
        )
        let refResult = try await refPipeline.analyze(files: files)
        #expect(refResult.cloneGroups.isEmpty)

        let cacheDirWT = repo.root + "/.swift-cpd-cache-wt"
        let wtPipeline = makePipeline(cacheDir: cacheDirWT)
        let wtResult = try await wtPipeline.analyze(files: files)
        #expect(!wtResult.cloneGroups.isEmpty)
    }

    private func makePipeline(
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

    private func loadCacheEnvelope(at directory: String) throws -> FileCache.Envelope {
        let url = URL(fileURLWithPath: directory).appendingPathComponent("cache.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FileCache.Envelope.self, from: data)
    }
}
