import Foundation

func runSwiftCPD(
    _ arguments: [String],
    workingDirectory: String? = nil,
    timeout: TimeInterval = 60
) throws -> (stdout: String, stderr: String, exitCode: Int32) {
    let binPath = productsDirectory().appendingPathComponent("swift-cpd")

    let process = Process()
    process.executableURL = binPath
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory ?? NSTemporaryDirectory())

    let outputDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("SwiftCPDProcess-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }

    let stdoutURL = outputDirectory.appendingPathComponent("stdout")
    let stderrURL = outputDirectory.appendingPathComponent("stderr")
    FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
    FileManager.default.createFile(atPath: stderrURL.path, contents: nil)

    let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
    let stderrHandle = try FileHandle(forWritingTo: stderrURL)
    defer {
        try? stdoutHandle.close()
        try? stderrHandle.close()
    }

    process.standardOutput = stdoutHandle
    process.standardError = stderrHandle

    try process.run()

    let deadline = Date().addingTimeInterval(timeout)
    while process.isRunning, Date() < deadline {
        Thread.sleep(forTimeInterval: 0.01)
    }

    if process.isRunning {
        process.terminate()
        process.waitUntilExit()
        throw ProcessTimeoutError(arguments: arguments, timeout: timeout)
    }

    let stdoutData = try Data(contentsOf: stdoutURL)
    let stderrData = try Data(contentsOf: stderrURL)

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
        .appendingPathComponent(".build/debug")
}

private func loadedImagePath() -> String? {
    let marker: @convention(c) () -> Void = {}
    var info = Dl_info()
    guard dladdr(unsafeBitCast(marker, to: UnsafeRawPointer.self), &info) != 0,
        let name = info.dli_fname
    else { return nil }
    return String(cString: name)
}
