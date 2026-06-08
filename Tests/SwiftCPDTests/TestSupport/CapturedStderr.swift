import Foundation

final class CapturedStderr: @unchecked Sendable {

    private let lock = NSLock()
    private var buffer = ""

    func append(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer += message
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}
