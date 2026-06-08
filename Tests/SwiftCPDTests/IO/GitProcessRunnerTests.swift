import Foundation
import Testing

@testable import swift_cpd

@Suite("GitProcessRunner")
struct GitProcessRunnerTests {

    @Test("Given git --version, when running, then exits zero with non-empty stdout")
    func runsKnownGitCommand() throws {
        let runner = GitProcessRunner()
        let result = try runner.run(args: ["--version"], workingDirectory: NSTemporaryDirectory())

        #expect(result.exitCode == 0)
        #expect(!result.stdout.isEmpty)
        #expect(String(data: result.stdout, encoding: .utf8)?.contains("git version") == true)
    }

    @Test("Given invalid git subcommand, when running, then exits non-zero with stderr populated")
    func reportsCommandFailure() throws {
        let runner = GitProcessRunner()
        let result = try runner.run(args: ["foobar"], workingDirectory: NSTemporaryDirectory())

        #expect(result.exitCode != 0)
        #expect(!result.stderr.isEmpty)
    }

    @Test("Given PATH without git, when running, then throws gitExecutableNotFound")
    func throwsWhenGitMissingFromPath() {
        let runner = GitProcessRunner(environment: ["PATH": ""])

        #expect(throws: SourceRefError.gitExecutableNotFound) {
            _ = try runner.run(args: ["--version"], workingDirectory: NSTemporaryDirectory())
        }
    }
}
