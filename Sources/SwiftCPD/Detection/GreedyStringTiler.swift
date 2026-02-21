struct GreedyStringTiler: Sendable {

    init(minimumTileSize: Int = 5) {
        self.minimumTileSize = minimumTileSize
    }

    let minimumTileSize: Int

    func similarity(between tokensA: [Token], and tokensB: [Token]) -> Double {
        let totalTokens = tokensA.count + tokensB.count

        guard
            totalTokens > 0
        else {
            return 0.0
        }

        var state = TilingState(sizeA: tokensA.count, sizeB: tokensB.count)
        computeTiles(tokensA: tokensA, tokensB: tokensB, state: &state)

        return (2.0 * Double(state.totalCovered)) / Double(totalTokens)
    }
}

extension GreedyStringTiler {

    private func computeTiles(tokensA: [Token], tokensB: [Token], state: inout TilingState) {
        var tileFound = true

        while tileFound {
            let matches = findLongestMatches(tokensA: tokensA, tokensB: tokensB, state: state)
            tileFound = applyMatches(matches, to: &state)
        }
    }

    private func findLongestMatches(
        tokensA: [Token],
        tokensB: [Token],
        state: TilingState
    ) -> [TileMatch] {
        var longestMatch = minimumTileSize
        var matches: [TileMatch] = []

        for indexA in 0 ..< tokensA.count where !state.markedA[indexA] {
            for indexB in 0 ..< tokensB.count where !state.markedB[indexB] {
                let length = matchLength(tokensA, tokensB, indexA, indexB, state)

                if length > longestMatch {
                    longestMatch = length
                    matches = [TileMatch(startA: indexA, startB: indexB, length: length)]
                } else if length == longestMatch {
                    matches.append(TileMatch(startA: indexA, startB: indexB, length: length))
                }
            }
        }

        return matches
    }

    private func applyMatches(_ matches: [TileMatch], to state: inout TilingState) -> Bool {
        var applied = false

        for match in matches {
            guard
                canApply(match, state: state)
            else {
                continue
            }

            for offset in 0 ..< match.length {
                state.markedA[match.startA + offset] = true
                state.markedB[match.startB + offset] = true
            }

            state.totalCovered += match.length
            applied = true
        }

        return applied
    }

    private func matchLength(
        _ tokensA: [Token],
        _ tokensB: [Token],
        _ startA: Int,
        _ startB: Int,
        _ state: TilingState
    ) -> Int {
        var length = 0
        var posA = startA
        var posB = startB

        while posA < tokensA.count, posB < tokensB.count {
            guard
                !state.markedA[posA],
                !state.markedB[posB],
                tokensA[posA].text == tokensB[posB].text
            else {
                break
            }

            length += 1
            posA += 1
            posB += 1
        }

        return length
    }

    private func canApply(_ match: TileMatch, state: TilingState) -> Bool {
        for offset in 0 ..< match.length {
            if state.markedA[match.startA + offset] || state.markedB[match.startB + offset] {
                return false
            }
        }

        return true
    }
}
