protocol DetectionAlgorithm: Sendable {

    var supportedCloneTypes: Set<CloneType> { get }

    func detect(files: [FileTokens]) -> [CloneGroup]
}
