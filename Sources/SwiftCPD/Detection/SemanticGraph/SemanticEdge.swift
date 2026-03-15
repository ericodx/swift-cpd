struct SemanticEdge: Sendable, Equatable, Hashable {

    let from: Int
    let to: Int
    let kind: SemanticEdgeKind
}
