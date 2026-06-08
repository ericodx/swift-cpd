import Foundation

struct GitProcessRunner: Sendable {

    init(environment: [String: String]? = nil) {
        self.environment = environment
    }

    private let environment: [String: String]?

    struct Result: Sendable {
        let stdout: Data
        let stderr: String
        let exitCode: Int32
    }

    func run(args: [String], workingDirectory: String) throws -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + args
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        if let environment {
            process.environment = environment
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw SourceRefError.gitExecutableNotFound
        }

        process.waitUntilExit()

        let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus == 127 {
            throw SourceRefError.gitExecutableNotFound
        }

        return Result(
            stdout: stdout,
            stderr: stderr,
            exitCode: process.terminationStatus
        )
    }
}
