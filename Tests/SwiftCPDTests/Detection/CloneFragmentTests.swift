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
}
