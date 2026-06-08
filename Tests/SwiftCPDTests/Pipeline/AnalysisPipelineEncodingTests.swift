import Foundation
import Testing

@testable import swift_cpd

@Suite("AnalysisPipeline source encoding")
struct AnalysisPipelineEncodingTests {

    @Test("Given file with non-UTF8 bytes, when analyzing, then throws fileReadInapplicableStringEncoding")
    func nonUtf8SourceThrows() async throws {
        let tempDir = createTempDirectory(prefix: "PipelineEncoding")
        defer { removeTempDirectory(tempDir) }

        let filePath = tempDir + "/Binary.swift"
        let invalidBytes = Data([0xC3, 0x28, 0xFF, 0xFE])
        try invalidBytes.write(to: URL(fileURLWithPath: filePath))

        let pipeline = AnalysisPipeline(
            detection: .init(minimumTokenCount: 5, minimumLineCount: 1),
            cache: .init(directory: tempDir + "/.cache", disabled: true)
        )

        await #expect(throws: CocoaError.self) {
            _ = try await pipeline.analyze(files: [filePath])
        }
    }
}
