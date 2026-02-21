struct AbstractSemanticGraph: Sendable, Equatable {

    let nodes: [SemanticNode]
    let edges: [SemanticEdge]
}
