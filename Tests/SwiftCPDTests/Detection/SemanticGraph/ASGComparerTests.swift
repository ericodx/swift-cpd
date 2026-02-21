import Testing

@testable import swift_cpd

@Suite("ASGComparer")
struct ASGComparerTests {

    let comparer = ASGComparer()

    @Test("Given identical graphs, when comparing, then similarity is 1.0")
    func identicalGraphs() {
        let graph = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .conditional),
                SemanticNode(id: 1, kind: .loop),
                SemanticNode(id: 2, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow),
                SemanticEdge(from: 1, to: 2, kind: .controlFlow),
            ]
        )

        let result = comparer.similarity(between: graph, and: graph)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given completely different graphs, when comparing, then similarity is 0.0")
    func completelyDifferent() {
        let graphA = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .loop),
                SemanticNode(id: 1, kind: .assignment),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow)
            ]
        )

        let graphB = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .conditional),
                SemanticNode(id: 1, kind: .errorHandling),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .dataFlow)
            ]
        )

        let result = comparer.similarity(between: graphA, and: graphB)

        #expect(result == 0.0)
    }

    @Test("Given both empty graphs, when comparing, then similarity is 1.0")
    func bothEmpty() {
        let result = comparer.similarity(
            between: AbstractSemanticGraph(nodes: [], edges: []),
            and: AbstractSemanticGraph(nodes: [], edges: [])
        )

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given one empty and one non-empty graph, when comparing, then similarity is 0.0")
    func oneEmpty() {
        let graph = AbstractSemanticGraph(
            nodes: [SemanticNode(id: 0, kind: .loop)],
            edges: []
        )

        let result = comparer.similarity(
            between: graph,
            and: AbstractSemanticGraph(nodes: [], edges: [])
        )

        #expect(result == 0.0)
    }

    @Test("Given partially overlapping graphs, when comparing, then similarity is between 0 and 1")
    func partialOverlap() {
        let graphA = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .conditional),
                SemanticNode(id: 1, kind: .loop),
                SemanticNode(id: 2, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow),
                SemanticEdge(from: 1, to: 2, kind: .controlFlow),
            ]
        )

        let graphB = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .conditional),
                SemanticNode(id: 1, kind: .assignment),
                SemanticNode(id: 2, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow),
                SemanticEdge(from: 1, to: 2, kind: .controlFlow),
            ]
        )

        let result = comparer.similarity(between: graphA, and: graphB)

        #expect(result > 0.0)
        #expect(result < 1.0)
    }

    @Test("Given graphs with no nodes and no edges, when comparing, then all component similarities return 1.0")
    func emptyGraphsAllComponents() {
        let emptyA = AbstractSemanticGraph(nodes: [], edges: [])
        let emptyB = AbstractSemanticGraph(nodes: [], edges: [])

        let result = comparer.similarity(between: emptyA, and: emptyB)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given graphs with nodes but no edges, when comparing, then edge similarity is 1.0")
    func nodesWithNoEdges() {
        let graphA = AbstractSemanticGraph(
            nodes: [SemanticNode(id: 0, kind: .loop)],
            edges: []
        )

        let graphB = AbstractSemanticGraph(
            nodes: [SemanticNode(id: 0, kind: .loop)],
            edges: []
        )

        let result = comparer.similarity(between: graphA, and: graphB)

        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Given one graph with edges and one without, when comparing, then lcs handles empty sequence")
    func oneGraphHasEdgesOtherDoesNot() {
        let graphA = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .loop),
                SemanticNode(id: 1, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow)
            ]
        )

        let graphB = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .loop),
                SemanticNode(id: 1, kind: .returnValue),
            ],
            edges: []
        )

        let result = comparer.similarity(between: graphA, and: graphB)

        #expect(result >= 0.0)
        #expect(result < 1.0)
    }

    @Test("Given graphs with same nodes but different edges, when comparing, then node similarity dominates")
    func sameNodesDifferentEdges() {
        let graphA = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .loop),
                SemanticNode(id: 1, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .controlFlow)
            ]
        )

        let graphB = AbstractSemanticGraph(
            nodes: [
                SemanticNode(id: 0, kind: .loop),
                SemanticNode(id: 1, kind: .returnValue),
            ],
            edges: [
                SemanticEdge(from: 0, to: 1, kind: .dataFlow)
            ]
        )

        let result = comparer.similarity(between: graphA, and: graphB)

        #expect(result >= 0.6)
    }
}
