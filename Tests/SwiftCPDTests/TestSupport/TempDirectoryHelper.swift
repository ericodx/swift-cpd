import Foundation

func createTempDirectory(prefix: String) -> String {
    let path = NSTemporaryDirectory() + prefix + "-" + UUID().uuidString
    try? FileManager.default.createDirectory(
        atPath: path,
        withIntermediateDirectories: true
    )
    return path
}

func removeTempDirectory(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
}

func createFile(at path: String, content: Data = Data()) {
    FileManager.default.createFile(atPath: path, contents: content)
}
