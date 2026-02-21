import SwiftSyntax

final class SemanticNormalizer: RangedSyntaxVisitor {

    private var nodes: [SemanticNode] = []
    private var edges: [SemanticEdge] = []
    private var nextId = 0
    private var definedVariableNodes: [String: Int] = [:]

    func normalize() -> AbstractSemanticGraph {
        run()
        return buildGraph()
    }

    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        let conditionalId = addNode(.conditional)

        if hasEarlyReturn(node.body) {
            addNode(.guardExit)
            addEdge(from: conditionalId, to: nodes.count - 1, kind: .controlFlow)
        }

        if hasOptionalBinding(node.conditions) {
            let unwrapId = addNode(.optionalUnwrap)
            addEdge(from: conditionalId, to: unwrapId, kind: .controlFlow)
        }

        return .visitChildren
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        if hasOptionalBinding(node.conditions) {
            addNode(.optionalUnwrap)
            return .visitChildren
        }

        let conditionalId = addNode(.conditional)

        if isNegatedEarlyReturn(node) {
            addNode(.guardExit)
            addEdge(from: conditionalId, to: nodes.count - 1, kind: .controlFlow)
        }

        return .visitChildren
    }

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .conditional)
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .loop)
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .loop)
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .loop)
    }

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .errorHandling)
    }

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .errorHandling)
    }

    override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .returnValue)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        let functionName = FunctionNameExtractor.extract(from: node.calledExpression)

        if isForEachCall(functionName) {
            addNode(.loop)
        } else if isCollectionOperation(functionName) {
            addNode(.collectionOperation)
        } else {
            addNode(.functionCall)
        }

        return .visitChildren
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        let assignmentId = addNode(.assignment)
        let variableName = node.pattern.trimmedDescription
        definedVariableNodes[variableName] = assignmentId

        if node.initializer != nil,
            containsLiteral(node)
        {
            addNode(.literalValue)
            addEdge(from: nodes.count - 1, to: assignmentId, kind: .dataFlow)
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        visitSimpleNode(node, kind: .parameterInput)
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        let name = node.baseName.text

        if let sourceNodeId = definedVariableNodes[name] {
            let currentId = nodes.count > 0 ? nodes.count - 1 : 0

            if currentId != sourceNodeId {
                addEdge(from: sourceNodeId, to: currentId, kind: .dataFlow)
            }
        }

        return .visitChildren
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        visitLiteralNode(node)
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        visitLiteralNode(node)
    }

    override func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        visitLiteralNode(node)
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        visitLiteralNode(node)
    }
}

extension SemanticNormalizer {

    private func buildGraph() -> AbstractSemanticGraph {
        guard
            nodes.count > 1
        else {
            return AbstractSemanticGraph(nodes: nodes, edges: edges)
        }

        var controlFlowEdges: [SemanticEdge] = []

        for index in 0 ..< nodes.count - 1 {
            let edge = SemanticEdge(
                from: nodes[index].id,
                to: nodes[index + 1].id,
                kind: .controlFlow
            )

            let alreadyExists = edges.contains { existing in
                existing.from == edge.from
                    && existing.to == edge.to
                    && existing.kind == edge.kind
            }

            if !alreadyExists {
                controlFlowEdges.append(edge)
            }
        }

        return AbstractSemanticGraph(
            nodes: nodes,
            edges: edges + controlFlowEdges
        )
    }

    private func visitSimpleNode(
        _ node: some SyntaxProtocol,
        kind: SemanticNodeKind
    ) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        addNode(kind)
        return .visitChildren
    }

    private func visitLiteralNode(_ node: some SyntaxProtocol) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .skipChildren
        }

        if !isPartOfBinding(node) {
            addNode(.literalValue)
        }

        return .visitChildren
    }

    @discardableResult
    private func addNode(_ kind: SemanticNodeKind) -> Int {
        let id = nextId
        nextId += 1
        nodes.append(SemanticNode(id: id, kind: kind))
        return id
    }

    private func addEdge(from: Int, to: Int, kind: SemanticEdgeKind) {
        edges.append(SemanticEdge(from: from, to: to, kind: kind))
    }

    private func hasEarlyReturn(_ body: CodeBlockSyntax) -> Bool {
        body.statements.contains { statement in
            statement.item.is(ReturnStmtSyntax.self)
                || statement.item.is(ThrowStmtSyntax.self)
        }
    }

    private func hasOptionalBinding(_ conditions: ConditionElementListSyntax) -> Bool {
        conditions.contains { condition in
            condition.condition.is(OptionalBindingConditionSyntax.self)
        }
    }

    private func isNegatedEarlyReturn(_ node: IfExprSyntax) -> Bool {
        let hasNegation = node.conditions.contains { condition in
            if let expr = condition.condition.as(ExprSyntax.self) {
                return expr.is(PrefixOperatorExprSyntax.self)
                    || expr.trimmedDescription.hasPrefix("!")
            }

            return false
        }

        guard
            hasNegation
        else {
            return false
        }

        let bodyStatements = node.body.statements

        return bodyStatements.contains { statement in
            statement.item.is(ReturnStmtSyntax.self)
                || statement.item.is(ThrowStmtSyntax.self)
        }
    }

    private func isForEachCall(_ name: String) -> Bool {
        name == "forEach"
    }

    private func isCollectionOperation(_ name: String) -> Bool {
        let collectionOps: Set<String> = [
            "map", "flatMap", "compactMap",
            "filter", "reduce",
            "sorted", "sort",
            "contains", "first", "last",
            "prefix", "suffix", "dropFirst", "dropLast",
        ]
        return collectionOps.contains(name)
    }

    private func containsLiteral(_ node: PatternBindingSyntax) -> Bool {
        let value = node.initializer!.value
        return value.is(IntegerLiteralExprSyntax.self)
            || value.is(StringLiteralExprSyntax.self)
            || value.is(FloatLiteralExprSyntax.self)
            || value.is(BooleanLiteralExprSyntax.self)
    }

    private func isPartOfBinding(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            if parent.is(PatternBindingSyntax.self) {
                return true
            }

            current = parent
        }

        return false
    }
}
