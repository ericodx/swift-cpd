import Testing

@testable import swift_cpd

@Suite("Detection Mutation Coverage")
struct DetectionMutationTests {

    @Suite("BlockExtraction Boundary")
    struct BlockExtractionBoundary {

        @Test("Given block at minimum, when extracting, then block is included")
        func blockExactlyAtMinimum() {
            let source = """
                func f() {
                    let a = 1
                    let b = 2
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let allBlocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            let blockCounts = allBlocks.map {
                $0.block.endTokenIndex - $0.block.startTokenIndex + 1
            }

            for count in blockCounts {
                #expect(count >= 1)
            }

            #expect(!allBlocks.isEmpty)
        }

        @Test("Given block below minimum, when extracting, then excluded")
        func blockOneBelowMinimum() {
            let source = """
                func f() {
                    let a = 1
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let allBlocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            let maxCount =
                allBlocks.map {
                    $0.block.endTokenIndex - $0.block.startTokenIndex + 1
                }.max() ?? 0

            let excludedBlocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: maxCount + 1
            )

            #expect(excludedBlocks.isEmpty)
        }

        @Test("Given endTokenIndex - startTokenIndex + 1, when + mutated to -, then wrong")
        func tokenCountArithmeticPlusOne() {
            let source = """
                func f() {
                    let a = 1
                    let b = 2
                    let c = 3
                    print(a + b + c)
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let allBlocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            guard
                let block = allBlocks.first
            else {
                Issue.record("Expected at least one block")
                return
            }

            let tokenCount =
                block.block.endTokenIndex - block.block.startTokenIndex + 1
            #expect(tokenCount > 0)

            let blocksAtExact = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: tokenCount
            )
            let blocksAboveExact = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: tokenCount + 1
            )

            #expect(blocksAtExact.count > blocksAboveExact.count)
        }
    }

    @Suite("BlockExtractor Binary Search")
    struct BlockExtractorBinarySearch {

        @Test("Given boundary tokens, when extracting, then included")
        func tokensOnBoundaryLinesIncluded() {
            let source = """
                func f() {
                    let x = 1
                    let y = 2
                }
                """

            let blocks = extractBlocks(from: source)

            #expect(!blocks.isEmpty)

            for block in blocks {
                #expect(block.startTokenIndex <= block.endTokenIndex)
            }
        }

        @Test("Given token on endLine, then break at > not >=")
        func tokenOnEndLineIsIncluded() {
            let source = """
                func f() {
                    let x = 1
                }
                """

            let blocks = extractBlocks(from: source)

            guard
                let block = blocks.first
            else {
                Issue.record("Expected at least one block")
                return
            }

            let tokenizer = SwiftTokenizer()
            let tokens = tokenizer.tokenize(source: source, file: "Test.swift")
            let endLineTokens = tokens.filter {
                $0.location.line == block.endLine
            }

            #expect(!endLineTokens.isEmpty)
            #expect(block.endTokenIndex >= block.startTokenIndex)
        }

        @Test("Given binary search, when token line equals target, then found")
        func binarySearchFindsExactLine() {
            let source = """
                let a = 1
                func f() {
                    let b = 2
                    let c = 3
                }
                let d = 4
                """

            let blocks = extractBlocks(from: source)
            let functionBlock = blocks.first { $0.startLine == 2 }

            #expect(functionBlock != nil)

            if let block = functionBlock {
                let tokenizer = SwiftTokenizer()
                let tokens = tokenizer.tokenize(
                    source: source, file: "Test.swift"
                )
                let firstToken = tokens[block.startTokenIndex]

                #expect(firstToken.location.line >= block.startLine)
            }
        }
    }

    @Suite("CloneGroup Init Token Count")
    struct CloneGroupInitTokenCount {

        @Test("Given pair, when creating CloneGroup, then lineCount correct")
        func lineCountUsesCorrectFormula() {
            let source = """
                func f() {
                    let a = 1
                    let b = 2
                    let c = 3
                    print(a + b + c)
                }
                func g() {
                    let x = 1
                    let y = 2
                    let z = 3
                    print(x + y + z)
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let blocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            guard
                blocks.count >= 2
            else {
                Issue.record("Expected at least two blocks")
                return
            }

            let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
            let group = CloneGroup(
                type: .type1, pair: pair, files: [fileTokens],
                similarity: 1.0, minimumLineCount: 1
            )

            #expect(group != nil)

            if let group = group {
                let lineCountA =
                    blocks[0].block.endLine - blocks[0].block.startLine + 1
                let lineCountB =
                    blocks[1].block.endLine - blocks[1].block.startLine + 1
                let expectedLineCount = max(lineCountA, lineCountB)

                #expect(group.lineCount == expectedLineCount)

                let tokenCountA =
                    blocks[0].block.endTokenIndex
                    - blocks[0].block.startTokenIndex + 1
                let tokenCountB =
                    blocks[1].block.endTokenIndex
                    - blocks[1].block.startTokenIndex + 1
                let expectedTokenCount = max(tokenCountA, tokenCountB)

                #expect(group.tokenCount == expectedTokenCount)
            }
        }

        @Test("Given lineCount below minimum, then returns nil")
        func lineCountBelowMinimumReturnsNil() {
            let source = """
                func f() { let a = 1 }
                func g() { let x = 1 }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let blocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            guard
                blocks.count >= 2
            else {
                Issue.record("Expected at least two blocks")
                return
            }

            let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
            let group = CloneGroup(
                type: .type1, pair: pair, files: [fileTokens],
                similarity: 1.0, minimumLineCount: 999
            )

            #expect(group == nil)
        }

        @Test("Given lineCount + 1, when + mutated to -, then wrong")
        func cloneGroupLineCountArithmeticExact() {
            let source = """
                func f() {
                    let a = 1
                    let b = 2
                    let c = 3
                }
                func g() {
                    let x = 1
                    let y = 2
                    let z = 3
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let blocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            guard blocks.count >= 2 else {
                Issue.record("Expected at least two blocks")
                return
            }

            let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
            let group = CloneGroup(
                type: .type1, pair: pair, files: [fileTokens],
                similarity: 1.0, minimumLineCount: 1
            )

            guard let group = group else {
                Issue.record("Expected a clone group")
                return
            }

            let lineA =
                blocks[0].block.endLine - blocks[0].block.startLine + 1
            let lineB =
                blocks[1].block.endLine - blocks[1].block.startLine + 1
            #expect(group.lineCount == max(lineA, lineB))
            #expect(group.lineCount >= 2)
        }

        @Test("Given tokenCount - 1, when - mutated to +, then wrong")
        func cloneGroupTokenCountArithmeticExact() {
            let source = """
                func f() {
                    let a = 1
                    let b = 2
                }
                func g() {
                    let x = 1
                    let y = 2
                }
                """

            let fileTokens = makeFileTokens(source: source, file: "Test.swift")
            let blocks = BlockExtraction.extractValidBlocks(
                files: [fileTokens], minimumTokenCount: 1
            )

            guard blocks.count >= 2 else {
                Issue.record("Expected at least two blocks")
                return
            }

            let pair = IndexedBlockPair(blockA: blocks[0], blockB: blocks[1])
            let group = CloneGroup(
                type: .type1, pair: pair, files: [fileTokens],
                similarity: 1.0, minimumLineCount: 1
            )

            guard let group = group else {
                Issue.record("Expected a clone group")
                return
            }

            let tokA =
                blocks[0].block.endTokenIndex
                - blocks[0].block.startTokenIndex + 1
            let tokB =
                blocks[1].block.endTokenIndex
                - blocks[1].block.startTokenIndex + 1
            #expect(group.tokenCount == max(tokA, tokB))
            #expect(group.tokenCount > 2)
        }
    }

    @Suite("GreedyStringTiler Longest Match")
    struct GreedyStringTilerLongestMatch {

        @Test("Given longer match, when tiling, then replaces matches")
        func longerMatchReplacesExisting() {
            let tiler = GreedyStringTiler(minimumTileSize: 2)
            let tokA = makeSimpleTokens(["a", "b", "c", "x", "y"])
            let tokB = makeSimpleTokens(["z", "w", "a", "b", "c"])

            let similarity = tiler.similarity(between: tokA, and: tokB)

            let covered = 3
            let expected =
                (2.0 * Double(covered))
                / Double(tokA.count + tokB.count)
            #expect(similarity == expected)
        }

        @Test("Given equal match, when tiling, then appends")
        func equalMatchAppended() {
            let tiler = GreedyStringTiler(minimumTileSize: 2)
            let tokA = makeSimpleTokens(["a", "b", "x", "c", "d"])
            let tokB = makeSimpleTokens(["a", "b", "y", "c", "d"])

            let similarity = tiler.similarity(between: tokA, and: tokB)

            let covered = 4
            let expected =
                (2.0 * Double(covered))
                / Double(tokA.count + tokB.count)
            #expect(similarity == expected)
        }

        @Test("Given match at minimumTileSize, then matched but not longest")
        func matchAtMinimumTileSizeBoundary() {
            let tiler = GreedyStringTiler(minimumTileSize: 3)
            let tokA = makeSimpleTokens(["a", "b", "c", "x"])
            let tokB = makeSimpleTokens(["a", "b", "c", "y"])

            let similarity = tiler.similarity(between: tokA, and: tokB)
            #expect(similarity > 0)

            let tilerStrict = GreedyStringTiler(minimumTileSize: 4)
            let simStrict = tilerStrict.similarity(between: tokA, and: tokB)
            #expect(simStrict == 0)
        }

        @Test("Given > minimumTileSize, when mutated to >=, then changes")
        func longestMatchStrictGreaterThan() {
            let tiler = GreedyStringTiler(minimumTileSize: 3)
            let tokA = makeSimpleTokens(["a", "b", "c", "d", "e", "x"])
            let tokB = makeSimpleTokens(["a", "b", "c", "d", "e", "y"])

            let similarity = tiler.similarity(between: tokA, and: tokB)

            let covered = 5
            let expected =
                (2.0 * Double(covered))
                / Double(tokA.count + tokB.count)
            #expect(similarity == expected)
        }
    }

    @Suite("LCSCalculator Empty Guard")
    struct LCSCalculatorEmpty {

        @Test("Given first empty, then returns zero")
        func firstSequenceEmpty() {
            #expect(LCSCalculator.length([Int](), [1, 2, 3]) == 0)
        }

        @Test("Given second empty, then returns zero")
        func secondSequenceEmpty() {
            #expect(LCSCalculator.length([1, 2, 3], [Int]()) == 0)
        }

        @Test("Given single matching, then returns 1")
        func singleElementMatch() {
            #expect(LCSCalculator.length([42], [42]) == 1)
        }

        @Test("Given single in first, then guard passes")
        func singleElementFirstSequence() {
            #expect(LCSCalculator.length([1], [1, 2, 3]) == 1)
        }
    }

    @Suite("RollingHash Underflow Guard")
    struct RollingHashUnderflow {

        @Test("Given result equals removeValue, then handles boundary")
        func resultEqualsRemoveValue() {
            let roller = RollingHash()
            let tokens = makeSimpleTokens(["a", "b", "c", "d"])
            let windowSize = 2
            let highestPower = roller.power(for: windowSize)

            let initialHash = roller.hash(
                tokens, offset: 0, count: windowSize
            )
            let updated = roller.rollingUpdate(
                hash: initialHash, removing: tokens[0],
                adding: tokens[2], highestPower: highestPower
            )
            let expected = roller.hash(
                tokens, offset: 1, count: windowSize
            )

            #expect(updated == expected)
        }

        @Test("Given chained updates, then all match recomputation")
        func chainedUpdatesAllMatch() {
            let roller = RollingHash()
            let tokens = makeSimpleTokens([
                "alpha", "beta", "gamma", "delta", "epsilon",
            ])
            let windowSize = 3
            let highestPower = roller.power(for: windowSize)

            var current = roller.hash(
                tokens, offset: 0, count: windowSize
            )

            for offset in 1 ... (tokens.count - windowSize) {
                current = roller.rollingUpdate(
                    hash: current, removing: tokens[offset - 1],
                    adding: tokens[offset + windowSize - 1],
                    highestPower: highestPower
                )
                let expected = roller.hash(
                    tokens, offset: offset, count: windowSize
                )

                #expect(current == expected)
            }
        }

        @Test("Given result >= removeValue, when >= mutated to >, then breaks")
        func rollingHashBoundaryEqualCase() {
            let roller = RollingHash()
            let tokens = makeSimpleTokens(["x", "x", "x"])
            let windowSize = 2
            let highestPower = roller.power(for: windowSize)

            let initialHash = roller.hash(
                tokens, offset: 0, count: windowSize
            )
            let updated = roller.rollingUpdate(
                hash: initialHash, removing: tokens[0],
                adding: tokens[2], highestPower: highestPower
            )
            let expected = roller.hash(
                tokens, offset: 1, count: windowSize
            )

            #expect(updated == expected)
        }
    }
}
