import Foundation

func repositoryRelativePath(for input: String, in repositoryRoot: String) throws -> String {
    let absolute = standardize(
        input.hasPrefix("/") ? input : repositoryRoot + "/" + input
    )
    let normalizedRoot = standardize(repositoryRoot)
    let rootWithSlash = normalizedRoot.hasSuffix("/") ? normalizedRoot : normalizedRoot + "/"

    if absolute == normalizedRoot {
        return ""
    }

    if absolute.hasPrefix(rootWithSlash) {
        return String(absolute.dropFirst(rootWithSlash.count))
    }

    throw FileDiscoveryError.pathOutsideRepository(
        path: input,
        repositoryRoot: repositoryRoot
    )
}

private func standardize(_ path: String) -> String {
    (path as NSString).standardizingPath
}
