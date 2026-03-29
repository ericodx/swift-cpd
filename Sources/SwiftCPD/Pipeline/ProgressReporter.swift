import Foundation

struct ProgressReporter: Sendable {

    init(totalFiles: Int, output: FileHandle = .standardError, delayNanoseconds: UInt64 = 5_000_000_000) {
        self.totalFiles = totalFiles
        self.output = output
        self.delayNanoseconds = delayNanoseconds
        self.state = ProgressState()
    }

    let totalFiles: Int
    let output: FileHandle
    let delayNanoseconds: UInt64

    private let state: ProgressState

    @discardableResult
    func start() async -> Task<Void, Never> {
        let total = totalFiles
        let delay = delayNanoseconds

        let task = Task {
            try? await Task.sleep(nanoseconds: delay)

            guard
                !Task.isCancelled
            else {
                return
            }

            writeProgress("Analyzing \(total) files...")
        }

        await state.storeTask(task)
        return task
    }

    func stop() async {
        await state.cancelTask()
    }
}

extension ProgressReporter {

    func writeProgress(_ message: String) {
        let data = Data((message + "\n").utf8)
        output.write(data)
    }
}
