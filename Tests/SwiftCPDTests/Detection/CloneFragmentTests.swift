import Testing

@testable import swift_cpd

@Suite("CloneFragment")
struct CloneFragmentTests {

    @Test("Given two identical fragments, when comparing, then they are equal")
    func equality() {
        let fragmentA = CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2)
        let fragmentB = CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2)

        #expect(fragmentA == fragmentB)
    }

    @Test("Given two different fragments, when comparing, then they are not equal")
    func inequality() {
        let fragmentA = CloneFragment(file: "A.swift", startLine: 1, endLine: 10, startColumn: 1, endColumn: 2)
        let fragmentB = CloneFragment(file: "B.swift", startLine: 5, endLine: 15, startColumn: 3, endColumn: 4)

        #expect(fragmentA != fragmentB)
    }

    @Test("Given a fragment, when accessing fields, then returns stored values")
    func fieldStorage() {
        let fragment = CloneFragment(file: "Main.swift", startLine: 10, endLine: 20, startColumn: 5, endColumn: 42)

        #expect(fragment.file == "Main.swift")
        #expect(fragment.startLine == 10)
        #expect(fragment.endLine == 20)
        #expect(fragment.startColumn == 5)
        #expect(fragment.endColumn == 42)
    }

    @Test(
        "Given tokens with known locations, when creating fragment, then endColumn equals last token column plus length"
    )
    func endColumnCalculation() {
        let tokens = [
            Token(kind: .keyword, text: "func", location: SourceLocation(file: "A.swift", line: 5, column: 3)),
            Token(kind: .identifier, text: "hello", location: SourceLocation(file: "A.swift", line: 5, column: 8)),
            Token(kind: .identifier, text: "world", location: SourceLocation(file: "A.swift", line: 6, column: 10)),
        ]

        let fragment = CloneFragment(file: "A.swift", tokens: tokens, startIndex: 0, endIndex: 2)

        #expect(fragment.file == "A.swift")
        #expect(fragment.startLine == 5)
        #expect(fragment.endLine == 6)
        #expect(fragment.startColumn == 3)
        #expect(fragment.endColumn == 15)
    }

    @Test("Given a single-character last token, when creating fragment, then endColumn equals column plus one")
    func endColumnWithSingleCharToken() {
        let tokens = [
            Token(kind: .identifier, text: "x", location: SourceLocation(file: "B.swift", line: 1, column: 1)),
            Token(kind: .identifier, text: "y", location: SourceLocation(file: "B.swift", line: 1, column: 4)),
        ]

        let fragment = CloneFragment(file: "B.swift", tokens: tokens, startIndex: 0, endIndex: 1)

        #expect(fragment.endColumn == 5)
    }

    @Test("Given a single token range, when creating fragment, then start and end lines match that token")
    func singleTokenFragment() {
        let tokens = [
            Token(kind: .identifier, text: "abc", location: SourceLocation(file: "C.swift", line: 7, column: 12))
        ]

        let fragment = CloneFragment(file: "C.swift", tokens: tokens, startIndex: 0, endIndex: 0)

        #expect(fragment.startLine == 7)
        #expect(fragment.endLine == 7)
        #expect(fragment.startColumn == 12)
        #expect(fragment.endColumn == 15)
    }
}
