import Foundation

func runSwiftCPD(
    _ arguments: [String],
    workingDirectory: String? = nil,
    timeout: TimeInterval = 60
) throws -> (stdout: String, stderr: String, exitCode: Int32) {
    let binPath = try swiftCPDExecutableURL()

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

/// Resolves the `swift-cpd` executable built alongside the test bundle.
///
/// The lookup does not depend on `Bundle.allBundles`: when the Swift Testing
/// tests run through `swiftpm-testing-helper` no `.xctest` bundle is registered
/// there, and a layout-specific fallback such as `.build/arm64-apple-macosx/debug`
/// breaks with Swift 6.4's default build system, which places products under
/// `.build/out/Products/Debug`. Instead, the package root is derived from
/// `#filePath` and the executable is expected at `.build/debug/swift-cpd`:
/// SwiftPM keeps `.build/debug` as a symlink to the active products directory
/// in both layouts.
func swiftCPDExecutableURL(filePath: String = #filePath) throws -> URL {
    let binPath = packageRoot(from: filePath)
        .appendingPathComponent(".build")
        .appendingPathComponent("debug")
        .appendingPathComponent("swift-cpd")

    guard FileManager.default.isExecutableFile(atPath: binPath.path) else {
        throw MissingExecutableError(path: binPath.path)
    }

    return binPath
}

func packageRoot(from filePath: String) -> URL {
    var url = URL(fileURLWithPath: filePath).deletingLastPathComponent()
    while url.pathComponents.count > 1 {
        let manifest = url.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: manifest.path) {
            return url
        }
        url = url.deletingLastPathComponent()
    }
    return url
}
