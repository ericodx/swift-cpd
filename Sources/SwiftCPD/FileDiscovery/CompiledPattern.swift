import Foundation

struct CompiledPattern: Sendable {

    let regex: NSRegularExpression
    let basenameOnly: Bool
}
