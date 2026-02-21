enum BlockExtraction {

    static func extractValidBlocks(
        files: [FileTokens],
        minimumTokenCount: Int
    ) -> [IndexedBlock] {
        let extractor = BlockExtractor()
        var allBlocks: [IndexedBlock] = []

        for (fileIndex, fileTokens) in files.enumerated() {
            let blocks = extractor.extract(
                source: fileTokens.source,
                file: fileTokens.file,
                tokens: fileTokens.normalizedTokens
            )

            let validBlocks = blocks.filter { block in
                let tokenCount = block.endTokenIndex - block.startTokenIndex + 1
                return tokenCount >= minimumTokenCount
            }

            for block in validBlocks {
                allBlocks.append(IndexedBlock(block: block, fileIndex: fileIndex))
            }
        }

        return allBlocks
    }
}
