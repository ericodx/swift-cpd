import SwiftSyntax

enum FunctionNameExtractor {

    static func extract(from expression: ExprSyntax) -> String {
        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text
        }

        if let declRef = expression.as(DeclReferenceExprSyntax.self) {
            return declRef.baseName.text
        }

        return expression.trimmedDescription
    }
}
