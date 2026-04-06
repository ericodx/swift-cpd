@testable import swift_cpd

func makeFragment(
    file: String,
    startLine: Int,
    endLine: Int,
    startColumn: Int = 1,
    endColumn: Int = 2
) -> CloneFragment {
    CloneFragment(
        file: file,
        startLine: startLine,
        endLine: endLine,
        startColumn: startColumn,
        endColumn: endColumn
    )
}

func makeCloneGroup(
    type: CloneType = .type1,
    tokenCount: Int = 10,
    lineCount: Int = 5,
    similarity: Double = 100.0,
    fragments: [CloneFragment]
) -> CloneGroup {
    CloneGroup(
        type: type,
        tokenCount: tokenCount,
        lineCount: lineCount,
        similarity: similarity,
        fragments: fragments
    )
}

func makeAnalysisResult(
    cloneGroups: [CloneGroup],
    filesAnalyzed: Int = 1,
    executionTime: Double = 0.1,
    totalTokens: Int = 100,
    minimumTokenCount: Int = 10,
    minimumLineCount: Int = 1
) -> AnalysisResult {
    AnalysisResult(
        cloneGroups: cloneGroups,
        filesAnalyzed: filesAnalyzed,
        executionTime: executionTime,
        totalTokens: totalTokens,
        minimumTokenCount: minimumTokenCount,
        minimumLineCount: minimumLineCount
    )
}
