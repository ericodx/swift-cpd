import Testing

@testable import swift_cpd

@Suite("SuppressionScanner")
struct SuppressionScannerTests {

    let scanner = SuppressionScanner()

    @Test("Given source without annotations, when scanning, then returns empty set")
    func noAnnotations() {
        let source = """
            func hello() {
                print("world")
            }
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.isEmpty)
    }

    @Test("Given annotation before single line, when scanning, then suppresses next line")
    func singleLineSuppression() {
        let source = """
            // swiftcpd:ignore
            let value = 42
            let other = 99
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(!suppressed.contains(3))
    }

    @Test("Given annotation before block, when scanning, then suppresses entire block")
    func blockSuppression() {
        let source = """
            // swiftcpd:ignore
            func hello() {
                print("world")
            }
            let after = true
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(suppressed.contains(3))
        #expect(suppressed.contains(4))
        #expect(!suppressed.contains(5))
    }

    @Test("Given annotation with leading whitespace, when scanning, then still detects it")
    func indentedAnnotation() {
        let source = """
                // swiftcpd:ignore
                let value = 42
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
    }

    @Test("Given block comment annotation, when scanning, then suppresses next declaration")
    func blockCommentAnnotation() {
        let source = """
            /* swiftcpd:ignore */
            let value = 42
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
    }

    @Test("Given annotation before nested block, when scanning, then suppresses all nested lines")
    func nestedBlockSuppression() {
        let source = """
            // swiftcpd:ignore
            func outer() {
                if true {
                    print("nested")
                }
            }
            let after = true
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(suppressed.contains(3))
        #expect(suppressed.contains(4))
        #expect(suppressed.contains(5))
        #expect(suppressed.contains(6))
        #expect(!suppressed.contains(7))
    }

    @Test("Given multiple annotations, when scanning, then suppresses all marked regions")
    func multipleAnnotations() {
        let source = """
            // swiftcpd:ignore
            let first = 1
            let middle = 2
            // swiftcpd:ignore
            let second = 3
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(!suppressed.contains(3))
        #expect(suppressed.contains(5))
    }

    @Test("Given annotation with empty line before declaration, when scanning, then skips empty line")
    func emptyLineBetweenAnnotationAndDeclaration() {
        let source = """
            // swiftcpd:ignore

            let value = 42
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(3))
        #expect(!suppressed.contains(2))
    }

    @Test("Given annotation at end of file, when scanning, then handles gracefully")
    func annotationAtEndOfFile() {
        let source = "// swiftcpd:ignore"

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
    }

    @Test("Given annotation with only empty lines after it, when scanning, then suppresses annotation line range")
    func annotationFollowedByOnlyEmptyLines() {
        let source = "// swiftcpd:ignore\n\n\n"

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
    }

    @Test("Given annotation before block without closing brace, when scanning, then suppresses until end of file")
    func unclosedBlockSuppression() {
        let source = """
            // swiftcpd:ignore
            func open() {
                let x = 1
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(suppressed.contains(3))
    }

    @Test("Given regular comment without tag, when scanning, then does not suppress")
    func regularCommentIgnored() {
        let source = """
            // this is a regular comment
            let value = 42
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.isEmpty)
    }

    @Test("Given annotation before class, when scanning, then suppresses entire class body")
    func classBlockSuppression() {
        let source = """
            // swiftcpd:ignore
            class Foo {
                var x = 1
                var y = 2
            }
            let after = true
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed == Set([2, 3, 4, 5]))
        #expect(!suppressed.contains(6))
    }

    @Test("Given custom tag, when scanning source with custom tag, then suppresses marked line")
    func customTagSuppression() {
        let customScanner = SuppressionScanner(tag: "nocpd")
        let source = """
            // nocpd
            let value = 42
            let other = 99
            """

        let suppressed = customScanner.suppressedLines(in: source)

        #expect(suppressed.contains(2))
        #expect(!suppressed.contains(3))
    }

    @Test("Given custom tag, when scanning source with default tag, then does not suppress")
    func customTagIgnoresDefaultTag() {
        let customScanner = SuppressionScanner(tag: "nocpd")
        let source = """
            // swiftcpd:ignore
            let value = 42
            """

        let suppressed = customScanner.suppressedLines(in: source)

        #expect(suppressed.isEmpty)
    }

    @Test("Given default tag scanner, when scanning source with custom tag, then does not suppress")
    func defaultTagIgnoresCustomTag() {
        let source = """
            // nocpd
            let value = 42
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.isEmpty)
    }

    @Test("Given suppression tag as last line with no following content, when scanning, then suppresses next line")
    func suppressionTagAtEndOfFile() {
        let source = "let x = 1\n// swiftcpd:ignore"

        let suppressed = scanner.suppressedLines(in: source)

        #expect(!suppressed.isEmpty)
    }

    @Test(
        "Given annotation before block with multiple empty lines, when scanning, then skips blanks and suppresses block"
    )
    func annotationWithMultipleBlankLinesBeforeBlock() {
        let source = """
            // swiftcpd:ignore


            func hello() {
                print("world")
            }
            let after = true
            """

        let suppressed = scanner.suppressedLines(in: source)

        #expect(suppressed.contains(4))
        #expect(suppressed.contains(5))
        #expect(suppressed.contains(6))
        #expect(!suppressed.contains(7))
    }
}
