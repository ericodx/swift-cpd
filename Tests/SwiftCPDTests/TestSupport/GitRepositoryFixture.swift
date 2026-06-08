import Foundation

@testable import swift_cpd

struct GitRepositoryFixture {

    init(prefix: String = "GitRepo") throws {
        self.root = createTempDirectory(prefix: prefix)
        self.runner = GitProcessRunner()

        try run("init", "-q", "-b", "main")
        try run("config", "user.email", "test@swift-cpd.local")
        try run("config", "user.name", "Test")
        try run("config", "commit.gpgsign", "false")
    }

    let root: String
    private let runner: GitProcessRunner

    @discardableResult
    func run(_ args: String...) throws -> GitProcessRunner.Result {
        try run(arguments: args)
    }

    @discardableResult
    func run(arguments: [String]) throws -> GitProcessRunner.Result {
        let result = try runner.run(args: arguments, workingDirectory: root)

        guard
            result.exitCode == 0
        else {
            throw FixtureError.gitFailed(
                command: arguments.joined(separator: " "),
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        return result
    }

    func writeFile(_ relativePath: String, content: String) throws {
        try writeFile(relativePath, data: Data(content.utf8))
    }

    func writeFile(_ relativePath: String, data: Data) throws {
        let absolute = root + "/" + relativePath
        let directory = (absolute as NSString).deletingLastPathComponent

        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: URL(fileURLWithPath: absolute))
    }

    @discardableResult
    func commit(message: String = "snapshot") throws -> String {
        try run("add", "-A")
        try run("commit", "-q", "-m", message)
        return try resolveHead()
    }

    func stage(_ relativePath: String) throws {
        try run("add", "--", relativePath)
    }

    func checkout(_ ref: String) throws {
        try run("checkout", "-q", ref)
    }

    func createBranch(_ name: String) throws {
        try run("checkout", "-q", "-b", name)
    }

    func resolveHead() throws -> String {
        let result = try run("rev-parse", "HEAD")
        return String(data: result.stdout, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func cleanup() {
        removeTempDirectory(root)
    }

    enum FixtureError: Error {
        case gitFailed(command: String, exitCode: Int32, stderr: String)
    }
}
