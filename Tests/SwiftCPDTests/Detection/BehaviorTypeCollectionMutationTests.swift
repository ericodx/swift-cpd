import Testing

@testable import swift_cpd

@Suite("BehaviorSignatureExtractor Type Collection")
struct BehaviorTypeCollectionMutationTests {

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
