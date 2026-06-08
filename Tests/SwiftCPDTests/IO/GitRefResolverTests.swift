import Foundation
import Testing

@testable import swift_cpd

@Suite("GitRefResolver")
struct GitRefResolverTests {

    private let resolver = GitRefResolver()

    @Test("Given valid repo and HEAD, when resolving, then returns root and 40-char sha")
    func resolvesHead() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        let headSha = try repo.commit(message: "initial")

        let resolved = try resolver.resolve(ref: "HEAD", in: repo.root)

        #expect(resolved.resolvedSha == headSha)
        #expect(resolved.resolvedSha.count == 40)
        #expect(
            resolved.repositoryRoot.hasSuffix(
                (repo.root as NSString).lastPathComponent
            ))
    }

    @Test("Given unknown ref, when resolving, then throws unknownRef (G8)")
    func unknownRefThrows() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        try repo.commit()

        #expect(throws: SourceRefError.unknownRef(ref: "nonexistent/branch")) {
            _ = try resolver.resolve(ref: "nonexistent/branch", in: repo.root)
        }
    }

    @Test("Given non-repo directory, when resolving, then throws notARepository (G9)")
    func notARepoThrows() {
        let dir = createTempDirectory(prefix: "NotARepo")
        defer { removeTempDirectory(dir) }

        #expect(throws: SourceRefError.notARepository(workingDirectory: dir)) {
            _ = try resolver.resolve(ref: "HEAD", in: dir)
        }
    }

    @Test("Given commit history, when resolving HEAD~1, then returns prior commit sha")
    func resolvesAncestor() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "v1\n")
        let first = try repo.commit(message: "first")
        try repo.writeFile("Sources/A.swift", content: "v2\n")
        let second = try repo.commit(message: "second")

        let resolved = try resolver.resolve(ref: "HEAD~1", in: repo.root)

        #expect(resolved.resolvedSha == first)
        #expect(resolved.resolvedSha != second)
    }

    @Test("Given :0 (index), when resolving, then returns literal :0 as the resolved sha")
    func resolvesIndex() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.commit()

        let resolved = try resolver.resolve(ref: ":0", in: repo.root)

        #expect(resolved.resolvedSha == ":0")
        #expect(
            resolved.repositoryRoot.hasSuffix(
                (repo.root as NSString).lastPathComponent
            ))
    }

    @Test("Given branch name, when resolving, then returns its tip sha")
    func resolvesBranch() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "v1\n")
        try repo.commit(message: "main commit")

        try repo.createBranch("feature")
        try repo.writeFile("Sources/B.swift", content: "v2\n")
        let featureSha = try repo.commit(message: "feature commit")

        let resolved = try resolver.resolve(ref: "feature", in: repo.root)

        #expect(resolved.resolvedSha == featureSha)
    }
}
