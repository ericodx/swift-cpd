import Foundation

struct ProgressReporter: Sendable {

    init(totalFiles: Int, delayNanoseconds: UInt64 = 5_000_000_000) {
        self.totalFiles = totalFiles
        self.delayNanoseconds = delayNanoseconds
        self.state = ProgressState()
    }

    let totalFiles: Int
    let delayNanoseconds: UInt64

    private let state: ProgressState

    func start() {
        let total = totalFiles
        let stateRef = state
        let delay = delayNanoseconds

        let task = Task {
            try await Task.sleep(nanoseconds: delay)
            writeProgress("Analyzing \(total) files...")
        }

        Task {
            await stateRef.storeTask(task)
        }
    }

    func stop() async {
        await state.cancelTask()
    }
}

extension ProgressReporter {

    func writeProgress(_ message: String) {
        let data = Data((message + "\n").utf8)
        FileHandle.standardError.write(data)
    }
}
