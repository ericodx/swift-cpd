struct CacheKey: Hashable, Sendable {

    init(file: String, resolvedSha: String? = nil) {
        self.file = file
        self.resolvedSha = resolvedSha
    }

    let file: String
    let resolvedSha: String?

    var encoded: String {
        guard
            let resolvedSha
        else {
            return file
        }
        return "\(resolvedSha)|\(file)"
    }
}
