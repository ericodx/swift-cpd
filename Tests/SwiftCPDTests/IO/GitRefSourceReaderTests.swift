import Foundation
import Testing

@testable import swift_cpd

@Suite("GitRefSourceReader")
struct GitRefSourceReaderTests {

    @Test("Given file at HEAD, when reading, then returns its blob content (G4)")
    func readsBlobAtHead() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        let content = "let x = 1\n"
        try repo.writeFile("Sources/A.swift", content: content)
        let sha = try repo.commit()

        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)
        let data = try reader.read(file: "Sources/A.swift")

        #expect(String(data: data, encoding: .utf8) == content)
    }

    @Test("Given older commit, when reading file at that ref, then returns its historical bytes (G5)")
    func readsBlobAtAncestor() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        let first = try repo.commit(message: "first")
        try repo.writeFile("Sources/A.swift", content: "let x = 2\n")
        try repo.commit(message: "second")

        let reader = GitRefSourceReader(ref: "HEAD~1", resolvedSha: first, repositoryRoot: repo.root)
        let data = try reader.read(file: "Sources/A.swift")

        #expect(String(data: data, encoding: .utf8) == "let x = 1\n")
    }

    @Test("Given staged blob, when reading at :0, then returns the staged version (G6)")
    func readsStagedBlob() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        try repo.commit()

        try repo.writeFile("Sources/A.swift", content: "let x = 2\n")
        try repo.stage("Sources/A.swift")

        let reader = GitRefSourceReader(ref: ":0", resolvedSha: ":0", repositoryRoot: repo.root)
        let data = try reader.read(file: "Sources/A.swift")

        #expect(String(data: data, encoding: .utf8) == "let x = 2\n")
    }

    @Test("Given WT differs from HEAD, when reading at HEAD, then ignores WT (G7)")
    func ignoresWorkingTreeWhenReadingRef() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        let sha = try repo.commit()

        try repo.writeFile("Sources/A.swift", content: "let x = 999\n")

        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)
        let data = try reader.read(file: "Sources/A.swift")

        #expect(String(data: data, encoding: .utf8) == "let x = 1\n")
    }

    @Test("Given file absent in ref, when reading, then throws gitCommandFailed mentioning the path (G10)")
    func missingFileReportsError() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        try repo.writeFile("Sources/A.swift", content: "let x = 1\n")
        let sha = try repo.commit()

        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)

        #expect {
            _ = try reader.read(file: "Sources/Missing.swift")
        } throws: { error in
            guard
                case SourceRefError.gitCommandFailed(_, _, let stderr) = error
            else {
                return false
            }
            return stderr.contains("Sources/Missing.swift") || stderr.contains("Missing.swift")
        }
    }

    @Test("Given non-UTF8 blob, when reading, then returns raw bytes unchanged (G11)")
    func readsArbitraryBytes() throws {
        let repo = try GitRepositoryFixture()
        defer { repo.cleanup() }

        let bytes = Data([0x00, 0xFF, 0xFE, 0xC3, 0x28, 0x80])
        try repo.writeFile("Sources/Binary.swift", data: bytes)
        let sha = try repo.commit()

        let reader = GitRefSourceReader(ref: "HEAD", resolvedSha: sha, repositoryRoot: repo.root)
        let data = try reader.read(file: "Sources/Binary.swift")

        #expect(data == bytes)
    }
}
