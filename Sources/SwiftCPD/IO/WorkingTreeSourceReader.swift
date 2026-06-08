import Foundation

struct WorkingTreeSourceReader: SourceReader {

    func read(file: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: file))
    }
}
