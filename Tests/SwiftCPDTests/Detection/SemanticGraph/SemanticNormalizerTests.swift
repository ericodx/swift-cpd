import Testing

@testable import swift_cpd

@Suite("SemanticNormalizer")
struct SemanticNormalizerTests {

    @Test("Given empty function, when normalizing, then produces empty graph")
    func emptyFunction() {
        let source = """
            func doNothing() {
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 2).normalize()

        #expect(graph.nodes.isEmpty)
        #expect(graph.edges.isEmpty)
    }

    @Test("Given guard-else-return, when normalizing, then produces conditional and guardExit nodes")
    func guardElseReturn() {
        let source = """
            func process(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                return items.count
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
        #expect(kinds.contains(.guardExit))
    }

    @Test("Given if-not-return, when normalizing, then produces conditional and guardExit nodes")
    func ifNotReturn() {
        let source = """
            func process(_ items: [Int]) -> Int {
                if !items.isEmpty {
                    return 0
                }
                return items.count
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
        #expect(kinds.contains(.guardExit))
    }

    @Test("Given guard-else-return and if-not-return, when normalizing, then both produce guardExit")
    func guardAndIfNotReturnEquivalent() {
        let guardSource = """
            func processA(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                return items.count
            }
            """

        let ifSource = """
            func processB(_ items: [Int]) -> Int {
                if !items.isEmpty {
                    return 0
                }
                return items.count
            }
            """

        let guardGraph = SemanticNormalizer(source: guardSource, file: "a.swift", startLine: 1, endLine: 4).normalize()
        let ifGraph = SemanticNormalizer(source: ifSource, file: "b.swift", startLine: 1, endLine: 6).normalize()

        let guardKinds = guardGraph.nodes.map { $0.kind }
        let ifKinds = ifGraph.nodes.map { $0.kind }

        #expect(guardKinds.contains(.conditional))
        #expect(guardKinds.contains(.guardExit))
        #expect(ifKinds.contains(.conditional))
        #expect(ifKinds.contains(.guardExit))
    }

    @Test("Given for-in loop, when normalizing, then produces loop node")
    func forInLoop() {
        let source = """
            func sum(_ items: [Int]) -> Int {
                var total = 0
                for item in items {
                    total += item
                }
                return total
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 7).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.loop))
    }

    @Test("Given forEach call, when normalizing, then produces loop node")
    func forEachCall() {
        let source = """
            func process(_ items: [Int]) {
                items.forEach { item in
                    print(item)
                }
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 5).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.loop))
    }

    @Test("Given for-in and forEach, when normalizing, then both produce loop nodes")
    func forInAndForEachEquivalent() {
        let forSource = """
            func processA(_ items: [Int]) {
                for item in items {
                    print(item)
                }
            }
            """

        let forEachSource = """
            func processB(_ items: [Int]) {
                items.forEach { item in
                    print(item)
                }
            }
            """

        let forGraph = SemanticNormalizer(source: forSource, file: "a.swift", startLine: 1, endLine: 5).normalize()
        let forEachGraph = SemanticNormalizer(source: forEachSource, file: "b.swift", startLine: 1, endLine: 5)
            .normalize()

        let forLoopCount = forGraph.nodes.filter { $0.kind == .loop }.count
        let forEachLoopCount = forEachGraph.nodes.filter { $0.kind == .loop }.count

        #expect(forLoopCount > 0)
        #expect(forEachLoopCount > 0)
    }

    @Test("Given if-let, when normalizing, then produces optionalUnwrap node")
    func ifLetOptionalUnwrap() {
        let source = """
            func process(_ value: Int?) -> Int {
                if let unwrapped = value {
                    return unwrapped
                }
                return 0
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.optionalUnwrap))
    }

    @Test("Given guard-let, when normalizing, then produces optionalUnwrap node")
    func guardLetOptionalUnwrap() {
        let source = """
            func process(_ value: Int?) -> Int {
                guard let unwrapped = value else { return 0 }
                return unwrapped
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.optionalUnwrap))
    }

    @Test("Given map call, when normalizing, then produces collectionOperation node")
    func mapIsCollectionOperation() {
        let source = """
            func transform(_ items: [Int]) -> [String] {
                return items.map { String($0) }
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.collectionOperation))
    }

    @Test("Given filter call, when normalizing, then produces collectionOperation node")
    func filterIsCollectionOperation() {
        let source = """
            func filterPositive(_ items: [Int]) -> [Int] {
                return items.filter { $0 > 0 }
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.collectionOperation))
    }

    @Test("Given function with return, when normalizing, then produces returnValue node")
    func returnNode() {
        let source = """
            func identity(_ value: Int) -> Int {
                return value
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.returnValue))
    }

    @Test("Given switch statement, when normalizing, then produces conditional node")
    func switchIsConditional() {
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

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 8).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
    }

    @Test("Given do-catch, when normalizing, then produces errorHandling node")
    func doCatchIsErrorHandling() {
        let source = """
            func attempt() {
                do {
                    try riskyOperation()
                } catch {
                    print(error)
                }
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 7).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.errorHandling))
    }

    @Test("Given while loop, when normalizing, then produces loop node")
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

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 7).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.loop))
    }

    @Test("Given repeat-while loop, when normalizing, then produces loop node")
    func repeatWhileLoop() {
        let source = """
            func attempt() -> Int {
                var count = 0
                repeat {
                    count += 1
                } while count < 3
                return count
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 7).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.loop))
    }

    @Test("Given throw statement, when normalizing, then produces errorHandling node")
    func throwIsErrorHandling() {
        let source = """
            func validate(_ value: Int) throws {
                if value < 0 {
                    throw ValidationError.invalid
                }
            }
            enum ValidationError: Error { case invalid }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 5).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.errorHandling))
    }

    @Test("Given float literal outside binding, when normalizing, then produces literalValue node")
    func floatLiteralNode() {
        let source = """
            func compute() -> Double {
                return 3.14
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.literalValue))
    }

    @Test("Given variable assignment, when normalizing, then produces assignment node")
    func variableAssignment() {
        let source = """
            func process() {
                let x = 42
                print(x)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.assignment))
    }

    @Test("Given graph with multiple nodes, when normalizing, then edges connect sequential nodes")
    func sequentialControlFlowEdges() {
        let source = """
            func process(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                var total = 0
                for item in items {
                    total += item
                }
                return total
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 8).normalize()

        #expect(graph.nodes.count > 2)

        let controlFlowEdges = graph.edges.filter { $0.kind == .controlFlow }
        #expect(!controlFlowEdges.isEmpty)
    }

    @Test("Given source with many constructs, when normalizing restricted range, then ignores out-of-range nodes")
    func restrictedRangeSkipsOutOfRangeNodes() {
        let source = """
            func outer() {
                guard true else { return }
                if false { return }
                switch 0 { case 0: break; default: break }
                for _ in [] {}
                while false {}
                repeat {} while false
                do { try foo() } catch {}
                throw MyError()
                return
                foo()
                let x = 1
                bar(x)
                let y: Int = 2
                let z = 3.14
                let s = "hello"
                let b = true
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 18, endLine: 18).normalize()

        #expect(graph.nodes.count <= 2)
    }

    @Test("Given standalone literals and references outside range, when normalizing, then skips them")
    func outOfRangeLiteralsAndReferences() {
        let source = """
            func inRange() {
                guard items.isEmpty else { return }
            }
            func outOfRange() {
                x = y
                a = 42
                b = 3.14
                c = "hello"
                d = true
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
        #expect(!kinds.contains(.literalValue))
    }

    @Test("Given if with availability condition, when normalizing, then does not produce guardExit")
    func availabilityConditionNotGuardExit() {
        let source = """
            func check() {
                if #available(macOS 10.15, *) {
                    return
                }
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 5).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(!kinds.contains(.guardExit))
    }

    @Test("Given closure call expression, when normalizing, then produces functionCall node")
    func closureCallFallbackName() {
        let source = """
            func run() {
                ({ print("hi") })()
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.functionCall))
    }

    @Test("Given string literal in binding, when normalizing, then produces assignment and literalValue nodes")
    func stringLiteralInBinding() {
        let source = """
            func process() {
                let name = "hello"
                print(name)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.assignment))
        #expect(kinds.contains(.literalValue))
    }

    @Test("Given boolean literal in binding, when normalizing, then produces assignment and literalValue nodes")
    func booleanLiteralInBinding() {
        let source = """
            func process() {
                let flag = true
                print(flag)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.assignment))
        #expect(kinds.contains(.literalValue))
    }

    @Test("Given float literal in binding, when normalizing, then produces assignment and literalValue nodes")
    func floatLiteralInBinding() {
        let source = """
            func process() {
                let pi = 3.14
                print(pi)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.assignment))
        #expect(kinds.contains(.literalValue))
    }

    @Test("Given guard with throw in else body, when normalizing, then produces guardExit node")
    func guardElseThrow() {
        let source = """
            func validate(_ items: [Int]) throws {
                guard !items.isEmpty else { throw ValidationError.empty }
                process(items)
            }
            enum ValidationError: Error { case empty }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
        #expect(kinds.contains(.guardExit))
    }

    @Test("Given if with negation and return, when normalizing, then produces guardExit node")
    func negatedEarlyReturnProducesGuardExit() {
        let source = """
            func validate(_ value: Int) {
                if !isValid(value) {
                    return
                }
                process(value)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.guardExit))
    }
}
