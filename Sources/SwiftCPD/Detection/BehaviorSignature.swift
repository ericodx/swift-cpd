struct BehaviorSignature: Sendable, Equatable {

    let controlFlowShape: [ControlFlowNode]
    let dataFlowPatterns: [DataFlowPattern]
    let calledFunctions: Set<String>
    let typeSignatures: Set<String>
}
