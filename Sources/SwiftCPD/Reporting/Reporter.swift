protocol Reporter: Sendable {

    func report(_ result: AnalysisResult) -> String
}
