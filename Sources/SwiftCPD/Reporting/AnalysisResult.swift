import Foundation

struct AnalysisResult: Sendable {

    let cloneGroups: [CloneGroup]
    let filesAnalyzed: Int
    let executionTime: TimeInterval
    let totalTokens: Int
    let minimumTokenCount: Int
    let minimumLineCount: Int

    var sortedCloneGroups: [CloneGroup] {
        cloneGroups.sorted { lhs, rhs in
            if lhs.type.rawValue != rhs.type.rawValue {
                return lhs.type.rawValue < rhs.type.rawValue
            }

            if lhs.tokenCount != rhs.tokenCount {
                return lhs.tokenCount > rhs.tokenCount
            }

            guard
                let lhsFirst = lhs.fragments.first,
                let rhsFirst = rhs.fragments.first
            else {
                return false
            }

            if lhsFirst.file != rhsFirst.file {
                return lhsFirst.file < rhsFirst.file
            }

            return lhsFirst.startLine < rhsFirst.startLine
        }
    }
}
