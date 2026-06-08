import Foundation

struct GitRefSourceReader: SourceReader {

    init(
        ref: String,
        resolvedSha: String,
        repositoryRoot: String,
        runner: GitProcessRunner = GitProcessRunner()
    ) {
        self.ref = ref
        self.resolvedSha = resolvedSha
        self.repositoryRoot = repositoryRoot
        self.runner = runner
    }

    let ref: String
    let resolvedSha: String
    let repositoryRoot: String
    private let runner: GitProcessRunner

    func read(file: String) throws -> Data {
        let relative = try repositoryRelativePath(for: file)
        let spec = "\(resolvedSha):\(relative)"
        let result = try runner.run(
            args: ["cat-file", "blob", spec],
            workingDirectory: repositoryRoot
        )

        guard
            result.exitCode == 0
        else {
            throw SourceRefError.gitCommandFailed(
                command: "git cat-file blob \(spec)",
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        return result.stdout
    }
}

extension GitRefSourceReader {

    private func repositoryRelativePath(for file: String) throws -> String {
        let absolute = standardize(
            file.hasPrefix("/") ? file : repositoryRoot + "/" + file
        )
        let normalizedRoot = standardize(repositoryRoot)
        let rootWithSlash = normalizedRoot.hasSuffix("/") ? normalizedRoot : normalizedRoot + "/"

        if absolute == normalizedRoot {
            return ""
        }

        if absolute.hasPrefix(rootWithSlash) {
            return String(absolute.dropFirst(rootWithSlash.count))
        }

        if !file.hasPrefix("/") {
            return file
        }

        throw FileDiscoveryError.pathOutsideRepository(
            path: file,
            repositoryRoot: repositoryRoot
        )
    }

    private func standardize(_ path: String) -> String {
        (path as NSString).standardizingPath
    }
}
