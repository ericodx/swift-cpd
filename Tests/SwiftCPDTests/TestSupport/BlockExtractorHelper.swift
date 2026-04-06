@testable import swift_cpd

func extractBlocks(
    from source: String,
    file: String = "Test.swift"
) -> [CodeBlock] {
    let tokenizer = SwiftTokenizer()
    let extractor = BlockExtractor()
    let tokens = tokenizer.tokenize(source: source, file: file)
    return extractor.extract(
        source: source,
        file: file,
        tokens: tokens
    )
}
