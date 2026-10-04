import Foundation

struct MissingExecutableError: Error, CustomStringConvertible {
    let path: String

    var description: String {
        "swift-cpd executable not found at \(path); build the package with `swift build` before running the CLI tests"
    }
}
