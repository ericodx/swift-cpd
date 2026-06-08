import Foundation
import Testing

@testable import swift_cpd

@Suite("GitRefSourceFileLister")
struct GitRefSourceFileListerTests {

    @Test("Given Swift files committed at HEAD, when listing, then returns all of them (G1)")
    func listsFilesAtHead() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.writeFile("Sources/B.swift", content: "let b = 1\n")
        let sha = try repo.commit()

        let lister = makeLister(sha: sha, repoRoot: repo.root)
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("Sources/A.swift") })
        #expect(files.contains { $0.hasSuffix("Sources/B.swift") })
    }

    @Test("Given feature branch with additional files, when listing at the branch, then returns its tree (G2)")
    func listsFilesAtBranch() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.commit(message: "main")

        try repo.createBranch("feature")
        try repo.writeFile("Sources/C.swift", content: "let c = 1\n")
        let featureSha = try repo.commit(message: "feature")

        let lister = makeLister(sha: featureSha, repoRoot: repo.root, ref: "feature")
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("Sources/A.swift") })
        #expect(files.contains { $0.hasSuffix("Sources/C.swift") })
    }

    @Test("Given exclude pattern, when listing at ref, then omits matching files (G3)")
    func excludePatternsHonoured() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/Real.swift", content: "let x = 1\n")
        try repo.writeFile("Sources/Generated/Auto.swift", content: "let y = 2\n")
        let sha = try repo.commit()

        let lister = makeLister(
            sha: sha,
            repoRoot: repo.root,
            excludePatterns: ["**/Generated/**"]
        )
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Sources/Real.swift"))
    }

    @Test("Given mixed extensions in Swift-only mode, when listing, then keeps only .swift (G12)")
    func filtersByExtension() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.writeFile("Sources/B.md", content: "# README\n")
        try repo.writeFile("Sources/C.m", content: "/* objc */\n")
        let sha = try repo.commit()

        let lister = makeLister(sha: sha, repoRoot: repo.root)
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 1)
        #expect(files[0].hasSuffix("Sources/A.swift"))
    }

    @Test("Given cross-language mode, when listing, then includes C-family files alongside Swift")
    func crossLanguageIncludesCFamily() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.writeFile("Sources/Bridge.m", content: "/* objc */\n")
        let sha = try repo.commit()

        let lister = makeLister(sha: sha, repoRoot: repo.root, crossLanguageEnabled: true)
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 2)
    }

    @Test("Given linked worktree, when resolver gives the right root, then listing returns its tree (G13)")
    func worksFromLinkedWorktree() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.commit(message: "main commit")

        try repo.createBranch("feature")
        try repo.writeFile("Sources/B.swift", content: "let b = 1\n")
        try repo.commit(message: "feature commit")
        try repo.checkout("main")

        let worktreePath = repo.root + "-wt"
        try repo.run("worktree", "add", worktreePath, "feature")
        defer {
            removeTempDirectory(worktreePath)
            _ = try? repo.run("worktree", "prune")
        }

        let resolved = try GitRefResolver().resolve(ref: "feature", in: worktreePath)
        let lister = makeLister(
            sha: resolved.resolvedSha,
            repoRoot: resolved.repositoryRoot,
            ref: "feature"
        )
        let files = try lister.listFiles(in: ["Sources"])

        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("Sources/A.swift") })
        #expect(files.contains { $0.hasSuffix("Sources/B.swift") })
    }

    @Test("Given submodule entry, when listing, then skips it and warns to stderr")
    func skipsSubmoduleWithWarning() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        let headSha = try repo.commit(message: "main")

        try repo.run("update-index", "--add", "--cacheinfo", "160000,\(headSha),SubProject")

        let captured = CapturedStderr()
        let lister = makeLister(
            sha: ":0",
            repoRoot: repo.root,
            ref: ":0",
            stderr: { captured.append($0) }
        )
        let files = try lister.listFiles(in: [""])

        #expect(files.contains { $0.hasSuffix("Sources/A.swift") })
        #expect(!files.contains { $0.hasSuffix("SubProject") })
        #expect(captured.text.contains("SubProject"))
        #expect(captured.text.contains("submodule"))
    }

    @Test("Given path missing in ref, when listing, then throws pathDoesNotExistInRef")
    func missingPathThrowsRefAware() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        let sha = try repo.commit()

        let lister = makeLister(sha: sha, repoRoot: repo.root, ref: "HEAD")

        #expect {
            _ = try lister.listFiles(in: ["Missing"])
        } throws: { error in
            guard
                case FileDiscoveryError.pathDoesNotExistInRef(let path, let ref) = error
            else {
                return false
            }
            return path == "Missing" && ref == "HEAD"
        }
    }

    @Test("Given path outside repository, when listing, then throws pathOutsideRepository")
    func pathOutsideRepoThrows() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        let sha = try repo.commit()

        let lister = makeLister(sha: sha, repoRoot: repo.root)
        let outsidePath = "/tmp/definitely-outside-this-repo-\(UUID().uuidString)"

        #expect {
            _ = try lister.listFiles(in: [outsidePath])
        } throws: { error in
            guard
                case FileDiscoveryError.pathOutsideRepository(let path, let root) = error
            else {
                return false
            }
            return path == outsidePath && root == repo.root
        }
    }

    private func makeLister(
        sha: String,
        repoRoot: String,
        ref: String = "HEAD",
        crossLanguageEnabled: Bool = false,
        excludePatterns: [String] = [],
        stderr: (@Sendable (String) -> Void)? = nil
    ) -> GitRefSourceFileLister {
        if let stderr {
            return GitRefSourceFileLister(
                ref: ref,
                resolvedSha: sha,
                repositoryRoot: repoRoot,
                crossLanguageEnabled: crossLanguageEnabled,
                excludePatterns: excludePatterns,
                stderr: stderr
            )
        }
        return GitRefSourceFileLister(
            ref: ref,
            resolvedSha: sha,
            repositoryRoot: repoRoot,
            crossLanguageEnabled: crossLanguageEnabled,
            excludePatterns: excludePatterns
        )
    }
}
