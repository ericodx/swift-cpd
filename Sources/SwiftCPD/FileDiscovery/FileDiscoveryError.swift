enum FileDiscoveryError: Error, Sendable {

    case pathDoesNotExist(String)
    case pathDoesNotExistInRef(path: String, ref: String)
    case pathOutsideRepository(path: String, repositoryRoot: String)
}
