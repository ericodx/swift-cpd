@testable import swift_cpd

func makeGitRefSourceFileLister(
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
