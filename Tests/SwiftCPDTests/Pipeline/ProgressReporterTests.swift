import Testing

@testable import swift_cpd

@Suite("ProgressReporter", .serialized)
struct ProgressReporterTests {

    @Test("Given progress reporter stopped before delay, when stopped, then produces no output")
    func stopBeforeDelayProducesNoOutput() async {
        let output = await StderrCapture.captureAsync {
            let reporter = ProgressReporter(totalFiles: 10)
            await reporter.start()
            await reporter.stop()
        }

        #expect(output.isEmpty)
    }

    @Test("Given progress reporter, when created, then stores total files")
    func storesTotalFiles() {
        let reporter = ProgressReporter(totalFiles: 42)

        #expect(reporter.totalFiles == 42)
    }

    @Test("Given zero delay, when task completes, then writes progress to stderr")
    func writesProgressAfterDelay() async {
        let reporter = ProgressReporter(totalFiles: 5, delayNanoseconds: 0)
        let output = await StderrCapture.captureAsync {
            let task = await reporter.start()
            await task.value
        }
        await reporter.stop()

        #expect(output == "Analyzing 5 files...\n")
    }

    @Test("Given progress reporter, when writing message, then outputs message to stderr")
    func writeProgressDirectly() {
        let reporter = ProgressReporter(totalFiles: 1)
        let output = StderrCapture.capture {
            reporter.writeProgress("test")
        }

        #expect(output == "test\n")
    }
}
