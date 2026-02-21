import SwiftSyntax

final class BehaviorSignatureExtractor: RangedSyntaxVisitor {

    var controlFlowNodes: [ControlFlowNode] = []
    var calledFunctions: Set<String> = []
    var definedVariables: Set<String> = []
    var usedVariables: Set<String> = []
    var parameterNames: Set<String> = []
    var typeAnnotations: Set<String> = []

    func extract() -> BehaviorSignature {
        run()
        return buildSignature()
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.ifStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.guardStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.switchStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.forLoop)
        }

        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.whileLoop)
        }

        return .visitChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.repeatLoop)
        }

        return .visitChildren
    }

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.doCatch)
        }

        return .visitChildren
    }

    override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.returnStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.throwStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.breakStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            controlFlowNodes.append(.continueStatement)
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            let name = FunctionNameExtractor.extract(from: node.calledExpression)
            calledFunctions.insert(name)
        }

        return .visitChildren
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            let name = node.pattern.trimmedDescription
            definedVariables.insert(name)
        }

        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            let name = node.baseName.text
            usedVariables.insert(name)
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        guard
            isInRange(node)
        else {
            return .visitChildren
        }

        parameterNames.insert(node.secondName?.text ?? node.firstName.text)

        if let type = node.type.as(IdentifierTypeSyntax.self) {
            typeAnnotations.insert(type.name.text)
        }

        return .visitChildren
    }

    override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node),
            let type = node.type.as(IdentifierTypeSyntax.self)
        {
            typeAnnotations.insert(type.name.text)
        }

        return .visitChildren
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        if isInRange(node) {
            typeAnnotations.insert(node.name.text)
        }

        return .visitChildren
    }
}

extension BehaviorSignatureExtractor {

    private func buildSignature() -> BehaviorSignature {
        let dataFlowPatterns = computeDataFlowPatterns()

        return BehaviorSignature(
            controlFlowShape: controlFlowNodes,
            dataFlowPatterns: dataFlowPatterns,
            calledFunctions: calledFunctions,
            typeSignatures: typeAnnotations
        )
    }

    private func computeDataFlowPatterns() -> [DataFlowPattern] {
        var patterns: [DataFlowPattern] = []

        for variable in definedVariables {
            if usedVariables.contains(variable) {
                patterns.append(.defineAndUse)
            } else {
                patterns.append(.defineOnly)
            }
        }

        for variable in usedVariables {
            guard
                !definedVariables.contains(variable)
            else {
                continue
            }

            if parameterNames.contains(variable) {
                patterns.append(.parameterUse)
            } else {
                patterns.append(.useOnly)
            }
        }

        return patterns.sorted { $0.rawValue < $1.rawValue }
    }
}
