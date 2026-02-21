import Foundation

struct Type3Detector: DetectionAlgorithm {

    init(
        similarityThreshold: Double = 70.0,
        minimumTileSize: Int = 5,
        minimumTokenCount: Int = 50,
        minimumLineCount: Int = 5,
        candidateFilterThreshold: Double = 30.0
    ) {
        self.similarityThreshold = similarityThreshold
        self.minimumTileSize = minimumTileSize
        self.minimumTokenCount = minimumTokenCount
        self.minimumLineCount = minimumLineCount
        self.candidateFilterThreshold = candidateFilterThreshold
    }

    let similarityThreshold: Double
    let minimumTileSize: Int
    let minimumTokenCount: Int
    let minimumLineCount: Int
    let candidateFilterThreshold: Double

    var supportedCloneTypes: Set<CloneType> { [.type3] }

    func detect(files: [FileTokens]) -> [CloneGroup] {
        let blocks = BlockExtraction.extractValidBlocks(
            files: files,
            minimumTokenCount: minimumTokenCount
        )
        let candidates = filterCandidates(blocks: blocks, files: files)
        let clones = computeSimilarities(candidates: candidates, files: files)
        return CloneGroupDeduplicator.deduplicate(clones)
    }
}

extension Type3Detector {

    private func filterCandidates(
        blocks: [IndexedBlock],
        files: [FileTokens]
    ) -> [Type3CandidatePair] {
        let threshold = candidateFilterThreshold / 100.0
        var candidates: [Type3CandidatePair] = []

        let fingerprints = blocks.map { indexed in
            BlockFingerprint(
                tokens: files[indexed.fileIndex].normalizedTokens,
                startIndex: indexed.block.startTokenIndex,
                endIndex: indexed.block.endTokenIndex
            )
        }

        for first in 0 ..< blocks.count {
            for second in (first + 1) ..< blocks.count {
                let jaccard = fingerprints[first].jaccardSimilarity(with: fingerprints[second])

                guard
                    jaccard >= threshold
                else {
                    continue
                }

                candidates.append(
                    Type3CandidatePair(blockA: blocks[first], blockB: blocks[second])
                )
            }
        }

        return candidates
    }

    private func computeSimilarities(
        candidates: [Type3CandidatePair],
        files: [FileTokens]
    ) -> [CloneGroup] {
        let tiler = GreedyStringTiler(minimumTileSize: minimumTileSize)
        let threshold = similarityThreshold / 100.0

        return candidates.compactMap { pair in
            let tokensA = extractTokenSlice(pair.blockA, files: files)
            let tokensB = extractTokenSlice(pair.blockB, files: files)
            let similarity = tiler.similarity(between: tokensA, and: tokensB)

            guard
                similarity >= threshold
            else {
                return nil
            }

            return CloneGroupBuilder.buildCloneGroup(
                type: .type3,
                pair: IndexedBlockPair(blockA: pair.blockA, blockB: pair.blockB),
                files: files,
                similarity: similarity,
                minimumLineCount: minimumLineCount
            )
        }
    }

    private func extractTokenSlice(
        _ indexed: IndexedBlock,
        files: [FileTokens]
    ) -> [Token] {
        let tokens = files[indexed.fileIndex].normalizedTokens
        let start = indexed.block.startTokenIndex
        let end = indexed.block.endTokenIndex
        return Array(tokens[start ... end])
    }
}
