struct BehaviorSignatureComparer: Sendable {

    func similarity(
        between signatureA: BehaviorSignature,
        and signatureB: BehaviorSignature
    ) -> Double {
        let controlFlow = controlFlowSimilarity(signatureA.controlFlowShape, signatureB.controlFlowShape)
        let dataFlow = BagJaccardSimilarity.calculate(signatureA.dataFlowPatterns, signatureB.dataFlowPatterns)
        let calledFuncs = setJaccard(signatureA.calledFunctions, signatureB.calledFunctions)
        let types = setJaccard(signatureA.typeSignatures, signatureB.typeSignatures)

        return 0.4 * controlFlow + 0.3 * dataFlow + 0.2 * calledFuncs + 0.1 * types
    }
}

extension BehaviorSignatureComparer {

    private func controlFlowSimilarity(
        _ shapeA: [ControlFlowNode],
        _ shapeB: [ControlFlowNode]
    ) -> Double {
        LCSCalculator.similarity(shapeA, shapeB)
    }

    private func setJaccard(_ setA: Set<String>, _ setB: Set<String>) -> Double {
        guard
            !setA.isEmpty || !setB.isEmpty
        else {
            return 1.0
        }

        let intersection = setA.intersection(setB).count
        let union = setA.union(setB).count

        return Double(intersection) / Double(union)
    }
}
