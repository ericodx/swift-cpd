import Foundation

protocol SourceReader: Sendable {

    func read(file: String) throws -> Data
}
