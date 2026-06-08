extension AnalysisPipeline {

    struct DetectionOptions: Sendable {
        var minimumTokenCount: Int = 50
        var minimumLineCount: Int = 5
        var thresholds: DetectionThresholds = .defaults
        var enabledCloneTypes: Set<CloneType> = Set(CloneType.allCases)
        var crossLanguageEnabled: Bool = false
        var inlineSuppressionTag: String = "swiftcpd:ignore"
    }
}
