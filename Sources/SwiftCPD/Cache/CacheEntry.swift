struct CacheEntry: Sendable, Codable {

    let contentHash: String
    let tokens: [Token]
    let normalizedTokens: [Token]
}
