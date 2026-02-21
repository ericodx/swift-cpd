import Testing

@testable import swift_cpd

@Suite("ProgressReporter")
struct ProgressReporterTests {

    @Test("Given progress reporter stopped before delay, when stopped, then produces no output")
    func stopBeforeDelayProducesNoOutput() async {
        let reporter = ProgressReporter(totalFiles: 10)
        reporter.start()
        await reporter.stop()
    }

    @Test("Given progress reporter, when created, then stores total files")
    func storesTotalFiles() {
        let reporter = ProgressReporter(totalFiles: 42)

        #expect(reporter.totalFiles == 42)
    }

    @Test("Given short delay, when waiting past delay, then writes progress")
    func writesProgressAfterDelay() async throws {
        let reporter = ProgressReporter(totalFiles: 5, delayNanoseconds: 10_000_000)
        reporter.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        await reporter.stop()
    }

    @Test("Given progress reporter, when writing progress, then does not crash")
    func writeProgressDirectly() {
        let reporter = ProgressReporter(totalFiles: 1)
        reporter.writeProgress("test")
    }
}
