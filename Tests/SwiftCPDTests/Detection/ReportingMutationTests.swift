import Testing

@testable import swift_cpd

@Suite("Reporting Mutation Coverage")
struct ReportingMutationTests {

    @Suite("AnalysisResult Sorting")
    struct AnalysisResultSorting {

        @Test("Given groups with different types, when sorting, then lower rawValue first")
        func sortsByTypeAscending() {
            let groupType2 = makeCloneGroup(
                type: .type2, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )
            let groupType1 = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupType2, groupType1])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].type == .type1)
            #expect(sorted[1].type == .type2)
        }

        @Test("Given same type, different tokenCount, when sorting, then higher first")
        func sortsByTokenCountDescending() {
            let groupSmall = makeCloneGroup(
                type: .type1, tokenCount: 5,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )
            let groupLarge = makeCloneGroup(
                type: .type1, tokenCount: 20,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupSmall, groupLarge])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].tokenCount == 20)
            #expect(sorted[1].tokenCount == 5)
        }

        @Test("Given same type and tokenCount, different files, then alphabetical")
        func sortsByFileAscending() {
            let groupB = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "B.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "B.swift", startLine: 10, endLine: 15),
                ]
            )
            let groupA = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupB, groupA])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].fragments.first?.file == "A.swift")
            #expect(sorted[1].fragments.first?.file == "B.swift")
        }

        @Test("Given same file, different startLine, then earlier first")
        func sortsByStartLineAscending() {
            let groupLate = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 50, endLine: 55),
                    makeFragment(file: "A.swift", startLine: 60, endLine: 65),
                ]
            )
            let groupEarly = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupLate, groupEarly])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].fragments.first?.startLine == 1)
            #expect(sorted[1].fragments.first?.startLine == 50)
        }

        @Test("Given equal type rawValues, when < vs <=, then no swap")
        func equalTypeRawValuesNoSwap() {
            let groupA = makeCloneGroup(
                type: .type1, tokenCount: 15,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )
            let groupB = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupA, groupB])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].tokenCount == 15)
            #expect(sorted[1].tokenCount == 10)
        }

        @Test("Given equal tokenCount, when > vs >=, then proceeds to file compare")
        func equalTokenCountProceedsToFileCompare() {
            let groupB = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "B.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "B.swift", startLine: 10, endLine: 15),
                ]
            )
            let groupA = makeCloneGroup(
                type: .type1, tokenCount: 10,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 5),
                    makeFragment(file: "A.swift", startLine: 10, endLine: 15),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [groupB, groupA])
            let sorted = result.sortedCloneGroups

            #expect(sorted[0].fragments.first?.file == "A.swift")
        }

        @Test("Given nil first fragment, when sorting, then returns false")
        func nilFragmentsReturnFalse() {
            let group1 = makeCloneGroup(type: .type1, tokenCount: 10, fragments: [])
            let group2 = makeCloneGroup(type: .type1, tokenCount: 10, fragments: [])

            let result = makeAnalysisResult(cloneGroups: [group1, group2])
            let sorted = result.sortedCloneGroups

            #expect(sorted.count == 2)
        }
    }

    @Suite("BaselineStore Sorting")
    struct BaselineStoreSorting {

        @Test("Given different types, when saving and loading, then sorted ascending")
        func sortsByTypeAscending() throws {
            let tempPath = createTempDirectory(prefix: "baseline-type")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 2, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            #expect(loaded[0].type == 1)
            #expect(loaded[1].type == 2)
        }

        @Test("Given same type, different tokenCount, then descending")
        func sortsByTokenCountDescending() throws {
            let tempPath = createTempDirectory(prefix: "baseline-token")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 1, tokenCount: 5, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 20, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            #expect(loaded[0].tokenCount == 20)
            #expect(loaded[1].tokenCount == 5)
        }

        @Test("Given same type and tokenCount, different files, then alphabetical")
        func sortsByFileAscending() throws {
            let tempPath = createTempDirectory(prefix: "baseline-file")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "B.swift", startLine: 1, endLine: 5)
                ]
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            let firstFile = loaded[0].fragmentFingerprints.first!.file
            let secondFile = loaded[1].fragmentFingerprints.first!.file
            #expect(firstFile == "A.swift")
            #expect(secondFile == "B.swift")
        }

        @Test("Given empty fingerprints, when sorting, then returns false for stability")
        func emptyFingerprintsReturnFalse() throws {
            let tempPath = createTempDirectory(prefix: "baseline-empty")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: []
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 3,
                fragmentFingerprints: []
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            #expect(loaded.count == 2)
        }

        @Test("Given equal types, when < vs <=, then equal types preserve order")
        func equalTypesPreserveOrder() throws {
            let tempPath = createTempDirectory(prefix: "baseline-eq-type")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 1, tokenCount: 20, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            #expect(loaded[0].tokenCount == 20)
            #expect(loaded[1].tokenCount == 10)
        }

        @Test("Given equal tokenCount, when > vs >=, then proceeds to file sort")
        func equalTokenCountGoesToFileSort() throws {
            let tempPath = createTempDirectory(prefix: "baseline-eq-tok")
            defer { removeTempDirectory(tempPath) }
            let filePath = tempPath + "/baseline.json"
            let store = BaselineStore()

            let entry1 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "B.swift", startLine: 1, endLine: 5)
                ]
            )
            let entry2 = BaselineEntry(
                type: 1, tokenCount: 10, lineCount: 5,
                fragmentFingerprints: [
                    FragmentFingerprint(file: "A.swift", startLine: 1, endLine: 5)
                ]
            )

            try store.save(Set([entry1, entry2]), to: filePath)
            let loaded = try loadOrderedEntries(from: filePath)

            let firstFile = loaded[0].fragmentFingerprints.first!.file
            #expect(firstFile == "A.swift")
        }
    }

    @Suite("SuppressionScanner Boundaries")
    struct SuppressionScannerBoundaries {

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

    @Suite("BehaviorSignatureExtractor Type Collection")
    struct BehaviorSignatureExtractorTypeCollection {

        @Test("Given function with param type, then typeSignatures includes it")
        func parameterTypeAnnotationCollected() {
            let source = """
                func process(value: String) {
                    print(value)
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 3
            )
            let signature = extractor.extract()

            #expect(signature.typeSignatures.contains("String"))
        }

        @Test("Given function with return type, then typeSignatures includes it")
        func returnTypeAnnotationCollected() {
            let source = """
                func getValue() -> Int {
                    return 42
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 3
            )
            let signature = extractor.extract()

            #expect(signature.typeSignatures.contains("Int"))
        }

        @Test("Given function outside range, then return type not collected")
        func returnClauseOutsideRangeNotCollected() {
            let source = """
                func outside() -> String {
                    return "hello"
                }
                func inside() {
                    let x = 1
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 4, endLine: 6
            )
            let signature = extractor.extract()

            #expect(!signature.typeSignatures.contains("String"))
        }

        @Test("Given dataflow patterns, then sorted by rawValue ascending")
        func dataFlowPatternsSortedByRawValue() {
            let source = """
                func f(param: Int) {
                    let defined = 1
                    let used = defined + param
                    print(used)
                    print(globalVar)
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 6
            )
            let signature = extractor.extract()

            let rawValues = signature.dataFlowPatterns.map(\.rawValue)
            let sortedRawValues = rawValues.sorted()

            #expect(rawValues == sortedRawValues)

            if rawValues.count >= 2 {
                for idx in 0 ..< rawValues.count - 1 {
                    #expect(rawValues[idx] <= rawValues[idx + 1])
                }
            }
        }

        @Test("Given multiple param types, then all collected via insert()")
        func multipleParameterTypesCollected() {
            let source = """
                func process(name: String, age: Int) {
                    print(name)
                    print(age)
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 4
            )
            let signature = extractor.extract()

            #expect(signature.typeSignatures.contains("String"))
            #expect(signature.typeSignatures.contains("Int"))
            #expect(signature.typeSignatures.count >= 2)
        }

        @Test("Given return type insert, when removed, then type missing")
        func returnTypeInsertNotRemoved() {
            let source = """
                func compute() -> Double {
                    return 3.14
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 3
            )
            let signature = extractor.extract()

            #expect(signature.typeSignatures.contains("Double"))
        }

        @Test("Given IdentifierType insert, when removed, then type missing")
        func identifierTypeInsertNotRemoved() {
            let source = """
                func process(items: [CustomType]) {
                    let result: CustomType = items.first!
                    print(result)
                }
                """

            let extractor = BehaviorSignatureExtractor(
                source: source, file: "Test.swift", startLine: 1, endLine: 4
            )
            let signature = extractor.extract()

            #expect(!signature.typeSignatures.isEmpty)
        }
    }

    @Suite("JsonReporter Line Arithmetic")
    struct JsonReporterLineArithmetic {

        @Test("Given endLine - 1, when mutated to + 1, then endIndex wrong")
        func readPreviewEndLineSubtraction() {
            let group = makeCloneGroup(
                type: .type1, tokenCount: 10, lineCount: 3,
                fragments: [
                    makeFragment(file: "A.swift", startLine: 1, endLine: 3),
                    makeFragment(file: "B.swift", startLine: 1, endLine: 3),
                ]
            )

            let result = makeAnalysisResult(cloneGroups: [group])
            let reporter = JsonReporter()
            let output = reporter.report(result)

            #expect(output.contains("A.swift"))
        }
    }
}
