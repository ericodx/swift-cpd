enum DataFlowPattern: String, Sendable, Equatable, Hashable {

    case defineAndUse
    case defineOnly
    case useOnly
    case parameterUse
}
