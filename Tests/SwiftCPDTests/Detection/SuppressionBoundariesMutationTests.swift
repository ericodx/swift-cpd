import Testing

@testable import swift_cpd

@Suite("SuppressionScanner Boundaries")
struct SuppressionBoundariesMutationTests {

    @Test("Given tag on last line, when scanning, then suppresses next line")
    func suppressionTagOnLastLine() {
        let source = "let x = 1\n// swiftcpd:ignore\nlet y = 2"
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(3))
    }

    @Test("Given tag followed by block, then suppresses entire block")
    func suppressionTagFollowedByBlock() {
        let source = """
            // swiftcpd:ignore
            func f() {
                let x = 1
            }
            let after = 2
            """
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(suppressed.contains(3))
        #expect(suppressed.contains(4))
        #expect(!suppressed.contains(5))
    }

    @Test("Given tag at end of file, then handles boundary")
    func suppressionTagAtEndOfFile() {
        let source = "let x = 1\n// swiftcpd:ignore"
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(!suppressed.isEmpty)
    }

    @Test("Given startLine at boundary, then <= ensures processing")
    func startLineAtBoundary() {
        let source = "// swiftcpd:ignore\nlet x = 1"
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
    }

    @Test("Given block end at end of lines, then uses line - 1")
    func blockEndUsesCorrectLineOffset() {
        let source = """
            // swiftcpd:ignore
            func f() {
                let x = 1
            """
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(suppressed.contains(3))

        let maxSuppressed = suppressed.max() ?? 0
        #expect(maxSuppressed <= 3)
    }

    @Test("Given startLine <= lines.count, when <= mutated to <, then last line lost")
    func startLineEqualToLinesCount() {
        let source = "// swiftcpd:ignore"
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        #expect(!suppressed.isEmpty)
    }

    @Test("Given line - 1, when - mutated to +, then range end too large")
    func blockEndSubtractionNotAddition() {
        let source = """
            // swiftcpd:ignore
            func f() {
                let a = 1
                let b = 2
            """
        let scanner = SuppressionScanner()
        let suppressed = scanner.suppressedLines(in: source)

        let lineCount = source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).count
        let maxSuppressed = suppressed.max() ?? 0
        #expect(maxSuppressed <= lineCount)
    }
}
