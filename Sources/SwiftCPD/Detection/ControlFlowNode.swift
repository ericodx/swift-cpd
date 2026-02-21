enum ControlFlowNode: String, Sendable, Equatable, Hashable {

    case ifStatement
    case guardStatement
    case switchStatement
    case forLoop
    case whileLoop
    case repeatLoop
    case doCatch
    case returnStatement
    case throwStatement
    case breakStatement
    case continueStatement
}
