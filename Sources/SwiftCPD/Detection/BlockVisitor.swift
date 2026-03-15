import SwiftSyntax

final class BlockVisitor: SyntaxVisitor {

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    let converter: SourceLocationConverter
    var lineRanges: [(startLine: Int, endLine: Int)] = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            addRange(for: body)
        }

        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            addRange(for: body)
        }

        return .visitChildren
    }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            addRange(for: body)
        }

        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        addRange(for: Syntax(node))
        return .visitChildren
    }

    private func addRange(for node: CodeBlockSyntax) {
        addRange(for: Syntax(node))
    }

    private func addRange(for node: Syntax) {
        let start = converter.location(for: node.positionAfterSkippingLeadingTrivia)
        let end = converter.location(for: node.endPositionBeforeTrailingTrivia)
        lineRanges.append((startLine: start.line, endLine: end.line))
    }
}
