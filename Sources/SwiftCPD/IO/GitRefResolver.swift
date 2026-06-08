import Foundation

struct GitRefResolver: Sendable {

    init(runner: GitProcessRunner = GitProcessRunner()) {
        self.runner = runner
    }

    private let runner: GitProcessRunner

    func resolve(ref: String, in workingDirectory: String) throws -> Resolved {
        let repositoryRoot = try resolveRepositoryRoot(in: workingDirectory)

        if ref == ":0" {
            return Resolved(repositoryRoot: repositoryRoot, resolvedSha: ":0")
        }

        let resolvedSha = try resolveSha(of: ref, in: repositoryRoot)
        return Resolved(repositoryRoot: repositoryRoot, resolvedSha: resolvedSha)
    }
}

extension GitRefResolver {

    private func resolveRepositoryRoot(in workingDirectory: String) throws -> String {
        let result = try runner.run(
            args: ["rev-parse", "--show-toplevel"],
            workingDirectory: workingDirectory
        )

        guard
            result.exitCode == 0
        else {
            throw SourceRefError.notARepository(workingDirectory: workingDirectory)
        }

        return String(data: result.stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? workingDirectory
    }

    private func resolveSha(of ref: String, in repositoryRoot: String) throws -> String {
        let result = try runner.run(
            args: ["rev-parse", "--verify", "--quiet", ref],
            workingDirectory: repositoryRoot
        )

        guard
            result.exitCode == 0
        else {
            throw SourceRefError.unknownRef(ref: ref)
        }

        let sha =
            String(data: result.stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard
            !sha.isEmpty
        else {
            throw SourceRefError.unknownRef(ref: ref)
        }

        return sha
    }
}
