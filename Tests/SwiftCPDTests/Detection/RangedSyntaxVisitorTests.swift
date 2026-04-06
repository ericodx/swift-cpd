import Testing

@testable import swift_cpd

@Suite("RangedSyntaxVisitor")
struct RangedSyntaxVisitorTests {

    @Test("Given node exactly at endLine, when checking isInRange, then returns true")
    func nodeAtEndLine() {
        let source = """
            let x = 1
            let y = 2
            let z = 3
            """

        let extractor = BehaviorSignatureExtractor(
            source: source, file: "test.swift", startLine: 1, endLine: 2
        )
        let signature = extractor.extract()

        #expect(signature.dataFlowPatterns.count >= 2)
    }

    @Test("Given node exactly at startLine, when checking isInRange, then returns true")
    func nodeAtStartLine() {
        let source = """
            let x = 1
            let y = 2
            let z = 3
            """

        let extractor = BehaviorSignatureExtractor(
            source: source, file: "test.swift", startLine: 2, endLine: 3
        )
        let signature = extractor.extract()

        #expect(signature.dataFlowPatterns.count >= 2)
    }

    @Test("Given node outside range, when checking isInRange, then node is excluded")
    func nodeOutsideRange() {
        let source = """
            let x = 1
            let y = 2
            let z = 3
            """

        let extractor = BehaviorSignatureExtractor(
            source: source, file: "test.swift", startLine: 2, endLine: 2
        )
        let signature = extractor.extract()

        #expect(signature.dataFlowPatterns.count == 1)
    }
}
