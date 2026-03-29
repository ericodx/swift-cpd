import Foundation

func runSwiftCPD(
    _ arguments: [String],
    workingDirectory: String? = nil
) throws -> (stdout: String, stderr: String, exitCode: Int32) {
    let binPath = productsDirectory().appendingPathComponent("swift-cpd")

    let process = Process()
    process.executableURL = binPath
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory ?? NSTemporaryDirectory())

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    return (
        stdout: String(data: stdoutData, encoding: .utf8) ?? "",
        stderr: String(data: stderrData, encoding: .utf8) ?? "",
        exitCode: process.terminationStatus
    )
}

func productsDirectory() -> URL {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    process.arguments = ["build", "--show-bin-path"]
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    let output =
        String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return URL(fileURLWithPath: output.isEmpty ? ".build/debug" : output)
}
