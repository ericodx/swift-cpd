extension GitRefResolver {

    struct Resolved: Equatable, Sendable {
        let repositoryRoot: String
        let resolvedSha: String
    }
}
