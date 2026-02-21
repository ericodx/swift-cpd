struct ASGComparer: Sendable {

    func similarity(
        between graphA: AbstractSemanticGraph,
        and graphB: AbstractSemanticGraph
    ) -> Double {
        guard
            !graphA.nodes.isEmpty || !graphB.nodes.isEmpty
        else {
            return 1.0
        }

        guard
            !graphA.nodes.isEmpty,
            !graphB.nodes.isEmpty
        else {
            return 0.0
        }

        let nodeSim = BagJaccardSimilarity.calculate(
            graphA.nodes.map { $0.kind },
            graphB.nodes.map { $0.kind }
        )
        let edgeSim = edgeSimilarity(graphA.edges, graphB.edges)

        return 0.6 * nodeSim + 0.4 * edgeSim
    }
}

extension ASGComparer {

    private func edgeSimilarity(
        _ edgesA: [SemanticEdge],
        _ edgesB: [SemanticEdge]
    ) -> Double {
        LCSCalculator.similarity(edgesA.map { $0.kind }, edgesB.map { $0.kind })
    }
}
