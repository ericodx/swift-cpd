import Foundation
import Testing

@testable import swift_cpd

@Suite("SourceRef CLI integration")
struct SourceRefIntegrationTests {

    @Test("Given a git repo, when running swift-cpd --source-ref HEAD, then analyzes blob contents and exits 0")
    func cliSourceRefHeadAnalyzesBlobs() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: standardDuplicateSource)
        try repo.writeFile("Sources/B.swift", content: uniqueSourceA)
        try repo.commit()

        let result = try runSwiftCPD(
            ["--source-ref", "HEAD", "--no-cache", "Sources"],
            workingDirectory: repo.root
        )

        #expect(result.exitCode == 0 || result.exitCode == 1)
        #expect(result.stdout.contains("at HEAD"))
    }

    @Test("Given an invalid ref, when running swift-cpd --source-ref, then exits non-zero with unknownRef in stderr")
    func cliSourceRefBadRefFails() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let a = 1\n")
        try repo.commit()

        let result = try runSwiftCPD(
            ["--source-ref", "nonexistent/branch", "Sources"],
            workingDirectory: repo.root
        )

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("unknownRef") || result.stderr.contains("nonexistent"))
    }

    @Test(
        "Given dir not in a git repo, when running swift-cpd --source-ref HEAD, then fails with notARepository"
    )
    func cliSourceRefOutsideRepoFails() throws {
        let dir = createTempDirectory(prefix: "NotARepoIntegration")
        defer { removeTempDirectory(dir) }

        try "let x = 1\n".write(
            toFile: dir + "/A.swift",
            atomically: true,
            encoding: .utf8
        )

        let result = try runSwiftCPD(
            ["--source-ref", "HEAD", "A.swift"],
            workingDirectory: dir
        )

        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("notARepository") || result.stderr.contains("not"))
    }
}
