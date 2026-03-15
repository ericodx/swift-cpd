import Testing

@testable import swift_cpd

@Suite("BehaviorSignatureExtractor")
struct BehaviorSignatureExtractorTests {

    @Test("Given function with if/guard/for, when extracting, then controlFlowShape contains expected nodes")
    func controlFlowNodes() {
        let source = """
            func process(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    if item > 0 {
                        total += item
                    }
                }
                return total
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 10)
            .extract()

        #expect(signature.controlFlowShape.contains(.guardStatement))
        #expect(signature.controlFlowShape.contains(.forLoop))
        #expect(signature.controlFlowShape.contains(.ifStatement))
        #expect(signature.controlFlowShape.contains(.returnStatement))
    }

    @Test("Given function calling other functions, when extracting, then calledFunctions contains names")
    func calledFunctions() {
        let source = """
            func transform(_ items: [String]) -> [String] {
                return items.filter { !$0.isEmpty }.map { $0.uppercased() }
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 3)
            .extract()

        #expect(signature.calledFunctions.contains("filter"))
        #expect(signature.calledFunctions.contains("map"))
        #expect(signature.calledFunctions.contains("uppercased"))
    }

    @Test("Given function with variable definitions and uses, when extracting, then dataFlowPatterns are correct")
    func dataFlowPatterns() {
        let source = """
            func compute(_ input: Int) -> Int {
                let doubled = input * 2
                let result = doubled + 1
                return result
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 5)
            .extract()

        #expect(signature.dataFlowPatterns.contains(.defineAndUse))
        #expect(signature.dataFlowPatterns.contains(.parameterUse) || signature.dataFlowPatterns.contains(.useOnly))
    }

    @Test("Given function with type annotations, when extracting, then typeSignatures contains types")
    func typeAnnotations() {
        let source = """
            func format(_ value: Double) -> String {
                let text: String = String(value)
                return text
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 4)
            .extract()

        #expect(signature.typeSignatures.contains("String"))
        #expect(signature.typeSignatures.contains("Double"))
    }

    @Test("Given empty function body, when extracting, then signature has empty collections")
    func emptyFunction() {
        let source = """
            func doNothing() {
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 2)
            .extract()

        #expect(signature.controlFlowShape.isEmpty)
        #expect(signature.calledFunctions.isEmpty)
        #expect(signature.dataFlowPatterns.isEmpty)
    }

    @Test("Given function with nested control flow, when extracting, then all nodes captured in order")
    func nestedControlFlow() {
        let source = """
            func validate(_ items: [String]) -> Bool {
                for item in items {
                    if item.isEmpty {
                        return false
                    }
                }
                return true
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 8)
            .extract()

        let expectedOrder: [ControlFlowNode] = [.forLoop, .ifStatement, .returnStatement, .returnStatement]
        #expect(signature.controlFlowShape == expectedOrder)
    }

    @Test("Given function with while loop, when extracting, then whileLoop node present")
    func whileLoop() {
        let source = """
            func waitForResult() -> Int {
                var count = 0
                while count < 10 {
                    count += 1
                }
                return count
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 7)
            .extract()

        #expect(signature.controlFlowShape.contains(.whileLoop))
    }

    @Test("Given function with repeat-while, when extracting, then repeatLoop node present")
    func repeatWhileLoop() {
        let source = """
            func attemptRetry() -> Int {
                var attempts = 0
                repeat {
                    attempts += 1
                } while attempts < 3
                return attempts
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 7)
            .extract()

        #expect(signature.controlFlowShape.contains(.repeatLoop))
    }

    @Test("Given function with do-catch, when extracting, then doCatch node present")
    func doCatchStatement() {
        let source = """
            func attempt() -> Int {
                do {
                    let value = try riskyOperation()
                    return value
                } catch {
                    return 0
                }
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 8)
            .extract()

        #expect(signature.controlFlowShape.contains(.doCatch))
    }

    @Test("Given function with throw, when extracting, then throwStatement node present")
    func throwStatement() {
        let source = """
            func validate(_ value: Int) throws -> Int {
                if value < 0 {
                    throw ValidationError.invalid
                }
                return value
            }
            enum ValidationError: Error { case invalid }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 6)
            .extract()

        #expect(signature.controlFlowShape.contains(.throwStatement))
    }

    @Test("Given function with break, when extracting, then breakStatement node present")
    func breakStatement() {
        let source = """
            func findFirst(_ items: [Int]) -> Int? {
                for item in items {
                    if item > 10 {
                        break
                    }
                }
                return nil
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 8)
            .extract()

        #expect(signature.controlFlowShape.contains(.breakStatement))
    }

    @Test("Given function with continue, when extracting, then continueStatement node present")
    func continueStatement() {
        let source = """
            func sumPositive(_ items: [Int]) -> Int {
                var total = 0
                for item in items {
                    if item < 0 {
                        continue
                    }
                    total += item
                }
                return total
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 10)
            .extract()

        #expect(signature.controlFlowShape.contains(.continueStatement))
    }

    @Test("Given function with switch, when extracting, then switchStatement node present")
    func switchStatement() {
        let source = """
            func describe(_ value: Int) -> String {
                switch value {
                case 0:
                    return "zero"
                default:
                    return "other"
                }
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 8)
            .extract()

        #expect(signature.controlFlowShape.contains(.switchStatement))
        #expect(signature.controlFlowShape.contains(.returnStatement))
    }

    @Test("Given subscript call expression, when extracting, then uses trimmed description as function name")
    func subscriptCallFallback() {
        let source = """
            func process() {
                items[0]("arg")
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 3)
            .extract()

        #expect(!signature.calledFunctions.isEmpty)
    }

    @Test("Given variable defined but never used, when extracting, then produces defineOnly pattern")
    func defineOnlyPattern() {
        let source = """
            func unused() {
                let temporary = 42
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 3)
            .extract()

        #expect(signature.dataFlowPatterns.contains(.defineOnly))
    }

    @Test("Given parameter used in body, when extracting, then produces parameterUse pattern")
    func parameterUsePattern() {
        let source = """
            func greet(name: String) {
                print(name)
            }
            """

        let signature = BehaviorSignatureExtractor(source: source, file: "test.swift", startLine: 1, endLine: 3)
            .extract()

        #expect(signature.dataFlowPatterns.contains(.parameterUse))
    }
}
