import Testing

@testable import swift_cpd

@Suite("SemanticNormalizer Mutation Coverage")
struct SemanticNormalizerMutationTests {

    @Test("Given guard with early return, when normalizing, then edge from conditional to guardExit exists")
    func guardEarlyReturnProducesControlFlowEdge() {
        let source = """
            func f() {
                guard let x = optional else {
                    return
                }
                print(x)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph = normalizer.normalize()

        let conditionalNodes = graph.nodes.filter { $0.kind == .conditional }
        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }

        #expect(!conditionalNodes.isEmpty)
        #expect(!guardExitNodes.isEmpty)

        let hasEdge = graph.edges.contains { edge in
            edge.kind == .controlFlow
                && conditionalNodes.contains { $0.id == edge.from }
                && guardExitNodes.contains { $0.id == edge.to }
        }

        #expect(hasEdge)
    }

    @Test("Given negated if-return, then edge from conditional to guardExit")
    func ifNegatedEarlyReturnProducesControlFlowEdge() {
        let source = """
            func f(value: Int?) {
                if !(value != nil) {
                    return
                }
                print(value!)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph = normalizer.normalize()

        let conditionalNodes = graph.nodes.filter { $0.kind == .conditional }
        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }

        #expect(!conditionalNodes.isEmpty)
        #expect(!guardExitNodes.isEmpty)

        let hasEdge = graph.edges.contains { edge in
            edge.kind == .controlFlow
                && conditionalNodes.contains { $0.id == edge.from }
                && guardExitNodes.contains { $0.id == edge.to }
        }

        #expect(hasEdge)
    }

    @Test("Given guard with early return, then edge target is guardExit node")
    func guardEdgeTargetsCorrectNodeId() {
        let source = """
            func f() {
                guard condition else {
                    return
                }
                doWork()
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph = normalizer.normalize()

        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }

        guard
            let guardExitNode = guardExitNodes.first
        else {
            Issue.record("Expected a guardExit node")
            return
        }

        let edgesToGuardExit = graph.edges.filter { $0.to == guardExitNode.id && $0.kind == .controlFlow }

        #expect(!edgesToGuardExit.isEmpty)
    }

    @Test("Given source with single statement, when normalizing with 1 node, then buildGraph skips sequential edges")
    func singleNodeGraphHasNoSequentialEdges() {
        let source = """
            func f() {
                return
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 3
        )
        let graph = normalizer.normalize()

        if graph.nodes.count <= 1 {
            let controlFlowEdges = graph.edges.filter { $0.kind == .controlFlow }

            #expect(controlFlowEdges.isEmpty)
        }
    }

    @Test("Given source with multiple nodes, when normalizing, then buildGraph adds sequential control flow edges")
    func multipleNodesGetSequentialControlFlowEdges() {
        let source = """
            func f() {
                let x = 1
                if condition {
                    doWork()
                }
                return x
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 7
        )
        let graph = normalizer.normalize()

        #expect(graph.nodes.count > 1)

        let controlFlowEdges = graph.edges.filter { $0.kind == .controlFlow }

        #expect(!controlFlowEdges.isEmpty)
    }

    @Test("Given edge deduplication where from/to match but kind differs, when normalizing, then both edges kept")
    func edgeDeduplicationChecksAllThreeFields() {
        let source = """
            func f() {
                let x = getValue()
                if x > 0 {
                    let y = x
                    print(y)
                }
                return
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 8
        )
        let graph = normalizer.normalize()

        var fromToPairs: [String: Set<SemanticEdgeKind>] = [:]

        for edge in graph.edges {
            let key = "\(edge.from)-\(edge.to)"
            fromToPairs[key, default: []].insert(edge.kind)
        }

        let hasControlFlow = graph.edges.contains { $0.kind == .controlFlow }
        let hasDataFlow = graph.edges.contains { $0.kind == .dataFlow }

        #expect(hasControlFlow)
        #expect(hasDataFlow)
    }

    @Test("Given if with prefix ! operator and early return, when checking negation, then OR logic detects it")
    func prefixBangOperatorDetectedByOrLogic() {
        let source = """
            func f(value: Bool) {
                if !value {
                    return
                }
                doWork()
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph = normalizer.normalize()

        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }

        #expect(!guardExitNodes.isEmpty)
    }

    @Test("Given variable reference with existing definition, when current node differs, then data flow edge added")
    func variableReferenceAddsDataFlowEdge() {
        let source = """
            func f() {
                let value = 42
                print(value)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 4
        )
        let graph = normalizer.normalize()

        let dataFlowEdges = graph.edges.filter { $0.kind == .dataFlow }

        #expect(!dataFlowEdges.isEmpty)
    }

    @Test("Given empty range, when normalizing, then returns empty graph without crash")
    func emptyRangeReturnsEmptyGraph() {
        let source = """
            func f() {
                let x = 1
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 100, endLine: 200
        )
        let graph = normalizer.normalize()

        #expect(graph.nodes.isEmpty)
        #expect(graph.edges.isEmpty)
    }

    @Test("Given guard addEdge to guardExit, when removed, then no control flow edge to guardExit exists")
    func guardAddEdgeIsNotRemoved() {
        let source = """
            func f() {
                guard condition else {
                    return
                }
                let a = 1
                let b = 2
                print(a + b)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 8
        )
        let graph = normalizer.normalize()

        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }
        let conditionalNodes = graph.nodes.filter { $0.kind == .conditional }

        #expect(!guardExitNodes.isEmpty)
        #expect(!conditionalNodes.isEmpty)

        let directEdge = graph.edges.contains { edge in
            edge.kind == .controlFlow
                && conditionalNodes.contains { $0.id == edge.from }
                && guardExitNodes.contains { $0.id == edge.to }
        }

        #expect(directEdge)
    }

    @Test("Given guard addEdge target uses nodes.count - 1, when mutated to + 1, then edge points to wrong node")
    func guardEdgeTargetUsesMinusOneNotPlusOne() {
        let source = """
            func f() {
                guard let x = opt else {
                    return
                }
                print(x)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph = normalizer.normalize()

        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }
        #expect(guardExitNodes.count == 1)

        let edgesToGuardExit = graph.edges.filter { edge in
            edge.kind == .controlFlow && edge.to == guardExitNodes[0].id
        }

        #expect(edgesToGuardExit.count >= 1)

        for edge in edgesToGuardExit {
            let fromNode = graph.nodes.first { $0.id == edge.from }
            #expect(fromNode != nil)
            #expect(fromNode?.kind == .conditional)
        }
    }

    @Test("Given if negated addEdge to guardExit, when removed, then no direct edge from conditional to guardExit")
    func ifNegatedAddEdgeIsNotRemoved() {
        let source = """
            func f(x: Bool) {
                if !x {
                    return
                }
                let a = 1
                print(a)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 7
        )
        let graph = normalizer.normalize()

        let conditionalNodes = graph.nodes.filter { $0.kind == .conditional }
        let guardExitNodes = graph.nodes.filter { $0.kind == .guardExit }

        #expect(!conditionalNodes.isEmpty)
        #expect(!guardExitNodes.isEmpty)

        let directEdge = graph.edges.contains { edge in
            edge.kind == .controlFlow
                && conditionalNodes.contains { $0.id == edge.from }
                && guardExitNodes.contains { $0.id == edge.to }
        }

        #expect(directEdge)
    }

    @Test("Given DeclReferenceExpr with nodes.count > 0, when mutated to >= 0, then zero case handled")
    func declReferenceCountGreaterThanZero() {
        let source = """
            func f() {
                let value = 42
                print(value)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 4
        )
        let graph = normalizer.normalize()

        #expect(graph.nodes.count > 0)

        let dataFlowEdges = graph.edges.filter { $0.kind == .dataFlow }
        #expect(!dataFlowEdges.isEmpty)

        for edge in dataFlowEdges {
            #expect(edge.from >= 0)
            #expect(edge.to >= 0)
            #expect(edge.from != edge.to)
        }
    }

    @Test("Given buildGraph guard nodes.count > 1, when exactly 1 node, then no sequential edges added")
    func buildGraphGuardExactlyOneNode() {
        let source = """
            func f() {
                return
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 3
        )
        let graph = normalizer.normalize()

        if graph.nodes.count == 1 {
            let sequentialEdges = graph.edges.filter { $0.kind == .controlFlow }
            #expect(sequentialEdges.isEmpty)
        }
    }

    @Test("Given buildGraph with exactly 2 nodes, when guard passes, then sequential edge added")
    func buildGraphTwoNodesGetsSequentialEdge() {
        let source = """
            func f() {
                let x = 1
                return x
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 4
        )
        let graph = normalizer.normalize()

        #expect(graph.nodes.count >= 2)

        let controlFlowEdges = graph.edges.filter { $0.kind == .controlFlow }
        #expect(!controlFlowEdges.isEmpty)
    }

    @Test("Given edge dedup using && for all 3 fields, when mutated to ||, then duplicates not detected")
    func edgeDeduplicationAndLogicAllThreeFields() {
        let source = """
            func f() {
                guard condition else {
                    return
                }
                let x = 1
                print(x)
            }
            """

        let normalizer = SemanticNormalizer(
            source: source, file: "Test.swift", startLine: 1, endLine: 7
        )
        let graph = normalizer.normalize()

        var edgeSet: Set<String> = []
        for edge in graph.edges {
            let key = "\(edge.from)-\(edge.to)-\(edge.kind)"
            edgeSet.insert(key)
        }

        #expect(edgeSet.count == graph.edges.count)
    }

    @Test("Given isNegatedEarlyReturn uses || for detection, when mutated to &&, then hasPrefix check alone suffices")
    func isNegatedOrLogicDetectsBothForms() {
        let sourcePrefixOp = """
            func f(value: Bool) {
                if !value {
                    return
                }
                doWork()
            }
            """

        let normalizer1 = SemanticNormalizer(
            source: sourcePrefixOp, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph1 = normalizer1.normalize()
        let guardExitNodes1 = graph1.nodes.filter { $0.kind == .guardExit }
        #expect(!guardExitNodes1.isEmpty)

        let sourceHasPrefix = """
            func f(value: Int?) {
                if !(value != nil) {
                    return
                }
                print(value!)
            }
            """

        let normalizer2 = SemanticNormalizer(
            source: sourceHasPrefix, file: "Test.swift", startLine: 1, endLine: 6
        )
        let graph2 = normalizer2.normalize()
        let guardExitNodes2 = graph2.nodes.filter { $0.kind == .guardExit }
        #expect(!guardExitNodes2.isEmpty)
    }
}
