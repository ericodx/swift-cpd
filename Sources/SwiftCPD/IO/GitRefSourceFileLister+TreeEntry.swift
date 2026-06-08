extension GitRefSourceFileLister {

    struct TreeEntry: Equatable, Sendable {

        static let submoduleMode = "160000"

        let mode: String
        let path: String

        var isSubmodule: Bool {
            mode == Self.submoduleMode
        }
    }
}
