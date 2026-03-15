import SwiftParser
import SwiftSyntax

class RangedSyntaxVisitor: SyntaxVisitor {

    init(source: String, file: String, startLine: Int, endLine: Int) {
        let sourceFile = Parser.parse(source: source)
        self.sourceFile = sourceFile
        self.converter = SourceLocationConverter(fileName: file, tree: sourceFile)
        self.startLine = startLine
        self.endLine = endLine
        super.init(viewMode: .sourceAccurate)
    }

    let sourceFile: SourceFileSyntax
    let converter: SourceLocationConverter
    let startLine: Int
    let endLine: Int

    func run() {
        walk(sourceFile)
    }

    func isInRange(_ node: some SyntaxProtocol) -> Bool {
        let location = converter.location(for: node.positionAfterSkippingLeadingTrivia)
        return location.line >= startLine && location.line <= endLine
    }
}
