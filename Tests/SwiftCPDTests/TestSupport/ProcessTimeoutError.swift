import Foundation

struct ProcessTimeoutError: Error, CustomStringConvertible {
    let arguments: [String]
    let timeout: TimeInterval

    var description: String {
        "swift-cpd did not exit within \(timeout)s (arguments: \(arguments.joined(separator: " ")))"
    }
}
