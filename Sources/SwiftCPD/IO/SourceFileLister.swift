protocol SourceFileLister: Sendable {

    func listFiles(in paths: [String]) throws -> [String]
}
