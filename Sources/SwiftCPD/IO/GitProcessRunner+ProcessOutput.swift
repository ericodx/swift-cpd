import Foundation

extension GitProcessRunner {

    struct ProcessOutput: Sendable {
        let stdout: Data
        let stderr: String
        let exitCode: Int32
    }
}
