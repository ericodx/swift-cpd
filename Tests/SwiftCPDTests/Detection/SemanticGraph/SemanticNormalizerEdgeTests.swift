import Testing

@testable import swift_cpd

@Suite("SemanticNormalizer — Edges")
struct SemanticNormalizerEdgeTests {

    @Test("Given if-not-return, when normalizing, then controlFlow edge connects conditional to guardExit")
    func ifNotReturnEdge() {
        let source = """
            func process(_ items: [Int]) -> Int {
                if !items.isEmpty {
                    return 0
                }
                return items.count
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let conditionalId = graph.nodes.first { $0.kind == .conditional }!.id
        let guardExitId = graph.nodes.first { $0.kind == .guardExit }!.id

        let hasEdge = graph.edges.contains {
            $0.from == conditionalId && $0.to == guardExitId && $0.kind == .controlFlow
        }
        #expect(hasEdge)
    }

    @Test("Given let with literal, when normalizing, then dataFlow edge connects literalValue to assignment")
    func patternBindingLiteralEdge() {
        let source = """
            func process() {
                let x = 42
                print(x)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let assignmentId = graph.nodes.first { $0.kind == .assignment }!.id
        let literalId = graph.nodes.first { $0.kind == .literalValue }!.id

        let hasDataFlowEdge = graph.edges.contains {
            $0.from == literalId && $0.to == assignmentId && $0.kind == .dataFlow
        }
        #expect(hasDataFlowEdge)
    }

    @Test("Given variable defined and used, when normalizing, then dataFlow edge connects assignment to usage site")
    func declReferenceDataFlowEdge() {
        let source = """
            func process() {
                let x = 42
                let y = x
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let assignments = graph.nodes.filter { $0.kind == .assignment }
        #expect(assignments.count >= 2)

        let firstAssignmentId = assignments[0].id
        let secondAssignmentId = assignments[1].id

        let hasDataFlowEdge = graph.edges.contains {
            $0.from == firstAssignmentId && $0.to == secondAssignmentId && $0.kind == .dataFlow
        }
        #expect(hasDataFlowEdge)
    }

    @Test("Given single node graph, when normalizing, then no controlFlow edges are added")
    func singleNodeGraphHasNoControlFlowEdges() {
        let source = """
            func process() -> Int {
                return 42
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        #expect(graph.nodes.count >= 1)

        let controlFlowEdges = graph.edges.filter { $0.kind == .controlFlow }

        if graph.nodes.count == 1 {
            #expect(controlFlowEdges.isEmpty)
        }
    }

    @Test("Given code that generates duplicate edges, when normalizing, then edges are deduplicated")
    func edgeDeduplication() {
        let source = """
            func process(_ items: [Int]) -> Int {
                guard !items.isEmpty else { return 0 }
                return items.count
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        for edge in graph.edges {
            let count = graph.edges.filter {
                $0.from == edge.from && $0.to == edge.to && $0.kind == edge.kind
            }.count
            #expect(count == 1)
        }
    }

    @Test("Given literal in binding, when normalizing, then isPartOfBinding prevents standalone literalValue")
    func literalInBindingNotDuplicated() {
        let source = """
            func process() {
                let x = 42
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let literalNodes = graph.nodes.filter { $0.kind == .literalValue }
        #expect(literalNodes.count == 1)
    }

    @Test("Given standalone literal, when normalizing, then literal is not suppressed by isPartOfBinding")
    func standaloneLiteralNotSuppressed() {
        let source = """
            func process() {
                print(42)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let literalNodes = graph.nodes.filter { $0.kind == .literalValue }
        #expect(literalNodes.count >= 1)
    }

    @Test("Given if with negation and throw, when normalizing, then produces guardExit node")
    func negatedEarlyThrowProducesGuardExit() {
        let source = """
            func validate(_ value: Int) throws {
                if !isValid(value) {
                    throw ValidationError.invalid
                }
                process(value)
            }
            enum ValidationError: Error { case invalid }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.guardExit))
    }

    @Test("Given if without negation, when normalizing, then does not produce guardExit")
    func ifWithoutNegationNoGuardExit() {
        let source = """
            func process(_ value: Int) -> Int {
                if value > 0 {
                    return value
                }
                return 0
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 6).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.conditional))
        #expect(!kinds.contains(.guardExit))
    }

    @Test("Given multiple nodes, when normalizing, then buildGraph adds sequential controlFlow edges")
    func buildGraphAddsSequentialEdges() {
        let source = """
            func process(_ items: [Int]) -> Int {
                var total = 0
                for item in items {
                    total += item
                }
                return total
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 7).normalize()

        #expect(graph.nodes.count > 2)

        for index in 0 ..< graph.nodes.count - 1 {
            let fromId = graph.nodes[index].id
            let toId = graph.nodes[index + 1].id

            let hasSequentialEdge = graph.edges.contains {
                $0.from == fromId && $0.to == toId && $0.kind == .controlFlow
            }
            #expect(hasSequentialEdge)
        }
    }

    @Test("Given variable used at same node, when normalizing, then no self-referencing dataFlow edge")
    func declReferenceNoSelfEdge() {
        let source = """
            func process() {
                let x = 42
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let selfEdges = graph.edges.filter { $0.from == $0.to }
        #expect(selfEdges.isEmpty)
    }

    @Test("Given variable never defined, when referenced, then no dataFlow edge added")
    func undefinedVariableNoDataFlowEdge() {
        let source = """
            func process(_ x: Int) -> Int {
                return x
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 3).normalize()

        let dataFlowEdges = graph.edges.filter { $0.kind == .dataFlow }
        #expect(dataFlowEdges.isEmpty)
    }

    @Test(
        "Given binding with type annotation and literal, when normalizing, then produces literalValue and dataFlow edge"
    )
    func bindingWithTypeAnnotationAndLiteral() {
        let source = """
            func process() {
                let x: Int = 42
                print(x)
            }
            """

        let graph = SemanticNormalizer(source: source, file: "test.swift", startLine: 1, endLine: 4).normalize()

        let kinds = graph.nodes.map { $0.kind }
        #expect(kinds.contains(.assignment))
        #expect(kinds.contains(.literalValue))

        let assignmentId = graph.nodes.first { $0.kind == .assignment }!.id
        let literalId = graph.nodes.first { $0.kind == .literalValue }!.id

        let hasDataFlow = graph.edges.contains {
            $0.from == literalId && $0.to == assignmentId && $0.kind == .dataFlow
        }
        #expect(hasDataFlow)
    }
}
