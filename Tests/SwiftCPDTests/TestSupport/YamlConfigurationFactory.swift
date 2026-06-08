@testable import swift_cpd

func makeYamlConfiguration(sourceRef: String? = nil) -> YamlConfiguration {
    YamlConfiguration(
        minimumTokenCount: nil,
        minimumLineCount: nil,
        outputFormat: nil,
        paths: nil,
        maxDuplication: nil,
        type3Similarity: nil,
        type3TileSize: nil,
        type3CandidateThreshold: nil,
        type4Similarity: nil,
        crossLanguageEnabled: nil,
        exclude: nil,
        inlineSuppressionTag: nil,
        enabledCloneTypes: nil,
        ignoreSameFile: nil,
        ignoreStructural: nil,
        noCache: nil,
        sourceRef: sourceRef
    )
}
