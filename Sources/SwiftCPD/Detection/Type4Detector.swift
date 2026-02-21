struct Type4Detector: DetectionAlgorithm {

    init(
        semanticSimilarityThreshold: Double = 80.0,
        minimumTokenCount: Int = 50,
        minimumLineCount: Int = 5
    ) {
        self.semanticSimilarityThreshold = semanticSimilarityThreshold
        self.minimumTokenCount = minimumTokenCount
        self.minimumLineCount = minimumLineCount
    }

    let semanticSimilarityThreshold: Double
    let minimumTokenCount: Int
    let minimumLineCount: Int

    var supportedCloneTypes: Set<CloneType> { [.type4] }

    func detect(files: [FileTokens]) -> [CloneGroup] {
        let signedBlocks = buildSignedBlocks(files: files)
        let candidates = filterCandidates(blocks: signedBlocks)
        let clones = computeSimilarities(candidates: candidates, files: files)
        return CloneGroupDeduplicator.deduplicate(clones)
    }
}

extension Type4Detector {

    private func buildSignedBlocks(
        files: [FileTokens]
    ) -> [SignedBlock] {
        let indexedBlocks = BlockExtraction.extractValidBlocks(
            files: files,
            minimumTokenCount: minimumTokenCount
        )

        return indexedBlocks.map { indexed in
            let source = files[indexed.fileIndex].source
            let file = indexed.block.file

            let extractor = BehaviorSignatureExtractor(
                source: source,
                file: file,
                startLine: indexed.block.startLine,
                endLine: indexed.block.endLine
            )
            let signature = extractor.extract()

            let normalizer = SemanticNormalizer(
                source: source,
                file: file,
                startLine: indexed.block.startLine,
                endLine: indexed.block.endLine
            )
            let graph = normalizer.normalize()

            return SignedBlock(indexed: indexed, signature: signature, graph: graph)
        }
    }

    private func filterCandidates(blocks: [SignedBlock]) -> [Type4CandidatePair] {
        var candidates: [Type4CandidatePair] = []

        for first in 0 ..< blocks.count {
            for second in (first + 1) ..< blocks.count {
                guard
                    passesPreFilter(blocks[first], blocks[second])
                else {
                    continue
                }

                candidates.append(
                    Type4CandidatePair(blockA: blocks[first], blockB: blocks[second])
                )
            }
        }

        return candidates
    }

    private func passesPreFilter(_ blockA: SignedBlock, _ blockB: SignedBlock) -> Bool {
        let lenA = blockA.signature.controlFlowShape.count
        let lenB = blockB.signature.controlFlowShape.count

        guard
            lenA > 0 || lenB > 0
        else {
            return true
        }

        let maxLen = max(lenA, lenB)
        let ratio = Double(min(lenA, lenB)) / Double(maxLen)
        return ratio >= 0.3
    }
}

extension Type4Detector {

    private func computeSimilarities(
        candidates: [Type4CandidatePair],
        files: [FileTokens]
    ) -> [CloneGroup] {
        let signatureComparer = BehaviorSignatureComparer()
        let graphComparer = ASGComparer()
        let threshold = semanticSimilarityThreshold / 100.0

        return candidates.compactMap { pair in
            let behaviorSimilarity = signatureComparer.similarity(
                between: pair.blockA.signature,
                and: pair.blockB.signature
            )

            let graphSimilarity = graphComparer.similarity(
                between: pair.blockA.graph,
                and: pair.blockB.graph
            )

            let combinedSimilarity = 0.6 * graphSimilarity + 0.4 * behaviorSimilarity

            guard
                combinedSimilarity >= threshold
            else {
                return nil
            }

            return CloneGroupBuilder.buildCloneGroup(
                type: .type4,
                pair: IndexedBlockPair(blockA: pair.blockA.indexed, blockB: pair.blockB.indexed),
                files: files,
                similarity: combinedSimilarity,
                minimumLineCount: minimumLineCount
            )
        }
    }
}
