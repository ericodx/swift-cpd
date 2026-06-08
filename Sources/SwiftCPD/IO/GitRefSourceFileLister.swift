import Foundation

struct GitRefSourceFileLister: SourceFileLister {

    init(
        ref: String,
        resolvedSha: String,
        repositoryRoot: String,
        crossLanguageEnabled: Bool,
        excludePatterns: [String] = [],
        runner: GitProcessRunner = GitProcessRunner(),
        stderr: @escaping @Sendable (String) -> Void = { message in
            FileHandle.standardError.write(Data(message.utf8))
        }
    ) {
        self.ref = ref
        self.resolvedSha = resolvedSha
        self.repositoryRoot = repositoryRoot
        self.crossLanguageEnabled = crossLanguageEnabled
        self.excludePatterns = excludePatterns
        self.runner = runner
        self.stderr = stderr
        self.globMatcher = GlobMatcher(patterns: excludePatterns)
    }

    private static let submoduleMode = "160000"
    private static let swiftExtensions: Set<String> = ["swift"]
    private static let cFamilyExtensions: Set<String> = ["m", "mm", "h", "c", "cpp"]

    let ref: String
    let resolvedSha: String
    let repositoryRoot: String
    let crossLanguageEnabled: Bool
    let excludePatterns: [String]

    private let runner: GitProcessRunner
    private let stderr: @Sendable (String) -> Void
    private let globMatcher: GlobMatcher

    struct TreeEntry: Equatable, Sendable {
        let mode: String
        let path: String

        var isSubmodule: Bool {
            mode == GitRefSourceFileLister.submoduleMode
        }
    }

    func listFiles(in paths: [String]) throws -> [String] {
        var collected: [String] = []

        for inputPath in paths {
            let relative = try repositoryRelativePath(for: inputPath, in: repositoryRoot)
            let entries = try lsEntries(scope: relative)

            guard
                !entries.isEmpty
            else {
                throw FileDiscoveryError.pathDoesNotExistInRef(path: inputPath, ref: ref)
            }

            for entry in entries {
                if entry.isSubmodule {
                    stderr("swift-cpd: skipping submodule '\(entry.path)' at \(ref)\n")
                    continue
                }

                guard
                    isValidExtension(entry.path)
                else {
                    continue
                }

                let absolute = repositoryRoot + "/" + entry.path

                if globMatcher.matches(absolute) {
                    continue
                }

                collected.append(absolute)
            }
        }

        return Array(Set(collected)).sorted()
    }
}

extension GitRefSourceFileLister {

    private func lsEntries(scope: String) throws -> [TreeEntry] {
        let result = try runListing(scope: scope)

        guard
            result.exitCode == 0
        else {
            throw SourceRefError.gitCommandFailed(
                command: listingCommandDescription(scope: scope),
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        let raw = String(data: result.stdout, encoding: .utf8) ?? ""
        return raw.split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap(parseEntry)
    }

    private func runListing(scope: String) throws -> GitProcessRunner.ProcessOutput {
        if resolvedSha == ":0" {
            var args = ["ls-files", "--stage"]
            if !scope.isEmpty {
                args += ["--", scope]
            }
            return try runner.run(args: args, workingDirectory: repositoryRoot)
        }

        var args = ["ls-tree", "-r", resolvedSha]
        if !scope.isEmpty {
            args += ["--", scope]
        }
        return try runner.run(args: args, workingDirectory: repositoryRoot)
    }

    private func listingCommandDescription(scope: String) -> String {
        let target = resolvedSha == ":0" ? "ls-files --stage" : "ls-tree -r \(resolvedSha)"
        return scope.isEmpty ? "git \(target)" : "git \(target) -- \(scope)"
    }

    private func parseEntry(_ line: Substring) -> TreeEntry? {
        guard
            let tabIndex = line.firstIndex(of: "\t")
        else {
            return nil
        }

        let header = line[..<tabIndex].split(separator: " ", omittingEmptySubsequences: true)

        guard
            let mode = header.first
        else {
            return nil
        }

        let path = String(line[line.index(after: tabIndex)...])
        return TreeEntry(mode: String(mode), path: path)
    }

    private func isValidExtension(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension

        if Self.swiftExtensions.contains(ext) {
            return true
        }

        if crossLanguageEnabled, Self.cFamilyExtensions.contains(ext) {
            return true
        }

        return false
    }
}
