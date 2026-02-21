import Foundation

func createTempFile(content: String, prefix: String = "Test") -> String {
    let path =
        NSTemporaryDirectory()
        + prefix + "-" + UUID().uuidString + ".yml"
    try? content.write(toFile: path, atomically: true, encoding: .utf8)
    return path
}

func removeTempFile(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
}
