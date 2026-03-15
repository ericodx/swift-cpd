enum SemanticNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {

    case assignment
    case functionCall
    case returnValue
    case conditional
    case loop
    case guardExit
    case errorHandling
    case collectionOperation
    case optionalUnwrap
    case parameterInput
    case literalValue
}
