enum SourceRefError: Error, Equatable, Sendable {

    case gitExecutableNotFound
    case notARepository(workingDirectory: String)
    case unknownRef(ref: String)
    case gitCommandFailed(command: String, exitCode: Int32, stderr: String)
}
