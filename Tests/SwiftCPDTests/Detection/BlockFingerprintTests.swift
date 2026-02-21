import Testing

@testable import swift_cpd

@Suite("BlockFingerprint")
struct BlockFingerprintTests {

    @Test("Given identical token sequences, when computing Jaccard, then similarity is 1.0")
    func identicalSequences() {
        let tokens = makeSimpleTokens(["let", "$ID", "=", "$NUM"])
        let fingerA = BlockFingerprint(tokens: tokens, startIndex: 0, endIndex: 3)
        let fingerB = BlockFingerprint(tokens: tokens, startIndex: 0, endIndex: 3)

        let similarity = fingerA.jaccardSimilarity(with: fingerB)

        #expect(similarity == 1.0)
    }

    @Test("Given completely different tokens, when computing Jaccard, then similarity is 0.0")
    func completelyDifferent() {
        let tokensA = makeSimpleTokens(["func", "run", "(", ")"])
        let tokensB = makeSimpleTokens(["let", "x", "=", "1"])
        let fingerA = BlockFingerprint(tokens: tokensA, startIndex: 0, endIndex: 3)
        let fingerB = BlockFingerprint(tokens: tokensB, startIndex: 0, endIndex: 3)

        let similarity = fingerA.jaccardSimilarity(with: fingerB)

        #expect(similarity == 0.0)
    }

    @Test("Given partially overlapping tokens, when computing Jaccard, then similarity is between 0 and 1")
    func partialOverlap() {
        let tokensA = makeSimpleTokens(["let", "$ID", "=", "$NUM", "print"])
        let tokensB = makeSimpleTokens(["let", "$ID", "=", "$STR", "return"])
        let fingerA = BlockFingerprint(tokens: tokensA, startIndex: 0, endIndex: 4)
        let fingerB = BlockFingerprint(tokens: tokensB, startIndex: 0, endIndex: 4)

        let similarity = fingerA.jaccardSimilarity(with: fingerB)

        #expect(similarity > 0.0)
        #expect(similarity < 1.0)
    }

    @Test("Given tokens with repeated values, when creating fingerprint, then counts frequencies")
    func countsFrequencies() {
        let tokens = makeSimpleTokens(["let", "let", "let", "x"])
        let fingerprint = BlockFingerprint(tokens: tokens, startIndex: 0, endIndex: 3)

        #expect(fingerprint.tokenFrequencies["let"] == 3)
        #expect(fingerprint.tokenFrequencies["x"] == 1)
    }

    @Test("Given subset of token array, when creating fingerprint, then uses only specified range")
    func respectsIndexRange() {
        let tokens = makeSimpleTokens(["func", "run", "let", "x", "=", "1"])
        let fingerprint = BlockFingerprint(tokens: tokens, startIndex: 2, endIndex: 5)

        #expect(fingerprint.tokenFrequencies["func"] == nil)
        #expect(fingerprint.tokenFrequencies["run"] == nil)
        #expect(fingerprint.tokenFrequencies["let"] == 1)
        #expect(fingerprint.tokenFrequencies["x"] == 1)
    }

    @Test("Given single identical token, when computing Jaccard, then similarity is 1.0")
    func singleTokenIdentical() {
        let tokensA = makeSimpleTokens(["x"])
        let tokensB = makeSimpleTokens(["x"])
        let fingerA = BlockFingerprint(tokens: tokensA, startIndex: 0, endIndex: 0)
        let fingerB = BlockFingerprint(tokens: tokensB, startIndex: 0, endIndex: 0)

        let similarity = fingerA.jaccardSimilarity(with: fingerB)

        #expect(similarity == 1.0)
    }

    @Test("Given same tokens in different order, when computing Jaccard, then similarity is 1.0")
    func orderIndependent() {
        let tokensA = makeSimpleTokens(["let", "x", "=", "1"])
        let tokensB = makeSimpleTokens(["=", "1", "let", "x"])
        let fingerA = BlockFingerprint(tokens: tokensA, startIndex: 0, endIndex: 3)
        let fingerB = BlockFingerprint(tokens: tokensB, startIndex: 0, endIndex: 3)

        let similarity = fingerA.jaccardSimilarity(with: fingerB)

        #expect(similarity == 1.0)
    }
}
