enum ConfigurationError: Error, Sendable, Equatable {

    case noPathsSpecified
    case parameterOutOfRange(name: String, value: Int, validRange: ClosedRange<Int>)
}
