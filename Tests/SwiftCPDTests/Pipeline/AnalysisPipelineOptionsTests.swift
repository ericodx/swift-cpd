import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline options structs")
struct AnalysisPipelineOptionsTests {

    @Test("Given DetectionOptions(), when reading defaults, then matches documented values")
    func detectionOptionsDefaults() {
        let options = AnalysisPipeline.DetectionOptions()

        #expect(options.minimumTokenCount == 50)
        #expect(options.minimumLineCount == 5)
        #expect(options.thresholds == .defaults)
        #expect(options.enabledCloneTypes == Set(CloneType.allCases))
        #expect(options.crossLanguageEnabled == false)
        #expect(options.inlineSuppressionTag == "swiftcpd:ignore")
    }

    @Test("Given SourceOptions(), when reading defaults, then reader is WorkingTreeSourceReader and sha is nil")
    func sourceOptionsDefaults() {
        let options = AnalysisPipeline.SourceOptions()

        #expect(options.reader is WorkingTreeSourceReader)
        #expect(options.resolvedSha == nil)
    }
}
