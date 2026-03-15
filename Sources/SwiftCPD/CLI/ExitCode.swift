enum ExitCode: Int32, Sendable {

    case success = 0
    case clonesDetected = 1
    case configurationError = 2
    case analysisError = 3
}
