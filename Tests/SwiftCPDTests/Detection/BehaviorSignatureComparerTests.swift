import Testing

@testable import swift_cpd

@Suite("BehaviorSignatureComparer")
struct BehaviorSignatureComparerTests {

    let comparer = BehaviorSignatureComparer()

    @Test("Given identical signatures, when comparing, then similarity is 1.0")
    func identicalSignatures() {
        let signature = BehaviorSignature(
            controlFlowShape: [.guardStatement, .forLoop, .ifStatement, .returnStatement],
            dataFlowPatterns: [.defineAndUse, .parameterUse],
            calledFunctions: ["filter", "map"],
            typeSignatures: ["String", "Int"]
        )

        let result = comparer.similarity(between: signature, and: signature)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given completely different signatures, when comparing, then similarity is 0.0")
    func completelyDifferent() {
        let signatureA = BehaviorSignature(
            controlFlowShape: [.forLoop, .ifStatement],
            dataFlowPatterns: [.defineAndUse],
            calledFunctions: ["filter"],
            typeSignatures: ["String"]
        )
        let signatureB = BehaviorSignature(
            controlFlowShape: [.switchStatement, .throwStatement],
            dataFlowPatterns: [.defineOnly],
            calledFunctions: ["reduce"],
            typeSignatures: ["Int"]
        )

        let result = comparer.similarity(between: signatureA, and: signatureB)

        #expect(result == 0.0)
    }

    @Test("Given both empty signatures, when comparing, then similarity is 1.0")
    func bothEmpty() {
        let signature = BehaviorSignature(
            controlFlowShape: [],
            dataFlowPatterns: [],
            calledFunctions: [],
            typeSignatures: []
        )

        let result = comparer.similarity(between: signature, and: signature)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given signatures differing only in control flow, when comparing, then max loss is 40%")
    func controlFlowWeight() {
        let signatureA = BehaviorSignature(
            controlFlowShape: [.forLoop],
            dataFlowPatterns: [.defineAndUse],
            calledFunctions: ["map"],
            typeSignatures: ["Int"]
        )
        let signatureB = BehaviorSignature(
            controlFlowShape: [.whileLoop],
            dataFlowPatterns: [.defineAndUse],
            calledFunctions: ["map"],
            typeSignatures: ["Int"]
        )

        let result = comparer.similarity(between: signatureA, and: signatureB)

        #expect(abs(result - 0.6) < 0.001)
    }

    @Test("Given signatures differing only in called functions, when comparing, then max loss is 20%")
    func calledFunctionsWeight() {
        let signatureA = BehaviorSignature(
            controlFlowShape: [.forLoop, .returnStatement],
            dataFlowPatterns: [.defineAndUse],
            calledFunctions: ["filter"],
            typeSignatures: ["String"]
        )
        let signatureB = BehaviorSignature(
            controlFlowShape: [.forLoop, .returnStatement],
            dataFlowPatterns: [.defineAndUse],
            calledFunctions: ["map"],
            typeSignatures: ["String"]
        )

        let result = comparer.similarity(between: signatureA, and: signatureB)

        #expect(abs(result - 0.8) < 0.001)
    }

    @Test(
        "Given signatures with empty data flow but non-empty other fields, when comparing, then data flow is 1.0"
    )
    func emptyDataFlowWithNonEmptyOtherFields() {
        let signatureA = BehaviorSignature(
            controlFlowShape: [.forLoop],
            dataFlowPatterns: [],
            calledFunctions: ["map"],
            typeSignatures: ["String"]
        )
        let signatureB = BehaviorSignature(
            controlFlowShape: [.forLoop],
            dataFlowPatterns: [],
            calledFunctions: ["map"],
            typeSignatures: ["String"]
        )

        let result = comparer.similarity(between: signatureA, and: signatureB)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given partially overlapping signatures, when comparing, then similarity is between 0 and 1")
    func partialOverlap() {
        let signatureA = BehaviorSignature(
            controlFlowShape: [.guardStatement, .forLoop, .ifStatement, .returnStatement],
            dataFlowPatterns: [.defineAndUse, .parameterUse],
            calledFunctions: ["filter", "map", "sorted"],
            typeSignatures: ["String", "Int"]
        )
        let signatureB = BehaviorSignature(
            controlFlowShape: [.guardStatement, .whileLoop, .ifStatement, .returnStatement],
            dataFlowPatterns: [.defineAndUse, .useOnly],
            calledFunctions: ["filter", "reduce"],
            typeSignatures: ["String", "Double"]
        )

        let result = comparer.similarity(between: signatureA, and: signatureB)

        #expect(result > 0.0)
        #expect(result < 1.0)
    }
}
