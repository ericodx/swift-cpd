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

    if let imagePath = loadedImagePath() {
        var url = URL(fileURLWithPath: imagePath)
        while url.pathExtension != "xctest", url.pathComponents.count > 1 {
            url = url.deletingLastPathComponent()
        }
        if url.pathExtension == "xctest" {
            return url.deletingLastPathComponent()
        }
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(".build/arm64-apple-macosx/debug")
}

private func loadedImagePath() -> String? {
    let marker: @convention(c) () -> Void = {}
    var info = Dl_info()
    guard dladdr(unsafeBitCast(marker, to: UnsafeRawPointer.self), &info) != 0,
        let name = info.dli_fname
    else { return nil }
    return String(cString: name)
}
