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
    if let bundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) {
        return bundle.bundleURL.deletingLastPathComponent()
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(".build/arm64-apple-macosx/debug")
}
