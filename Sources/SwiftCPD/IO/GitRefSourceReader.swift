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
        let relative = try repositoryRelativePath(for: file, in: repositoryRoot)
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
