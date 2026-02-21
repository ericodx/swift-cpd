struct CloneDetector: DetectionAlgorithm {

    init(minimumTokenCount: Int = 50, minimumLineCount: Int = 5) {
        self.minimumTokenCount = minimumTokenCount
        self.minimumLineCount = minimumLineCount
    }

    let minimumTokenCount: Int
    let minimumLineCount: Int

    var supportedCloneTypes: Set<CloneType> { [.type1, .type2] }

    private let rollingHash = RollingHash()

    func detect(files: [FileTokens]) -> [CloneGroup] {
        let candidates = findCandidates(files)
        let verified = verifyCandidates(candidates, files: files)
        let expanded = expandRegions(verified, files: files)
        let classified = classifyClones(expanded, files: files)
        let deduplicated = deduplicateClones(classified, files: files)
        return filterByMinimumLineCount(deduplicated)
    }
}

extension CloneDetector {

    private func findCandidates(_ files: [FileTokens]) -> [UInt64: [TokenLocation]] {
        var hashTable: [UInt64: [TokenLocation]] = [:]
        let highestPower = rollingHash.power(for: minimumTokenCount)

        for (fileIndex, fileTokens) in files.enumerated() {
            let tokens = fileTokens.normalizedTokens

            guard
                tokens.count >= minimumTokenCount
            else {
                continue
            }

            var currentHash = rollingHash.hash(tokens, offset: 0, count: minimumTokenCount)
            let firstLocation = TokenLocation(fileIndex: fileIndex, offset: 0)
            hashTable[currentHash, default: []].append(firstLocation)

            for offset in 1 ..< (tokens.count - minimumTokenCount + 1) {
                currentHash = rollingHash.rollingUpdate(
                    hash: currentHash,
                    removing: tokens[offset - 1],
                    adding: tokens[offset + minimumTokenCount - 1],
                    highestPower: highestPower
                )

                let location = TokenLocation(fileIndex: fileIndex, offset: offset)
                hashTable[currentHash, default: []].append(location)
            }
        }

        return hashTable.filter { $0.value.count > 1 }
    }

    private func verifyCandidates(
        _ candidates: [UInt64: [TokenLocation]],
        files: [FileTokens]
    ) -> [ClonePair] {
        var pairs: [ClonePair] = []

        for (_, locations) in candidates {
            for first in 0 ..< locations.count {
                for second in (first + 1) ..< locations.count {
                    let locationA = locations[first]
                    let locationB = locations[second]

                    guard
                        !isOverlapping(locationA, locationB)
                    else {
                        continue
                    }

                    let tokensA = files[locationA.fileIndex].normalizedTokens
                    let tokensB = files[locationB.fileIndex].normalizedTokens

                    if tokensMatch(
                        tokensA, offsetA: locationA.offset,
                        tokensB, offsetB: locationB.offset,
                        count: minimumTokenCount
                    ) {
                        pairs.append(
                            ClonePair(
                                locationA: locationA,
                                locationB: locationB,
                                tokenCount: minimumTokenCount
                            )
                        )
                    }
                }
            }
        }

        return pairs
    }

    private func expandRegions(
        _ pairs: [ClonePair],
        files: [FileTokens]
    ) -> [ClonePair] {
        pairs.map { pair in
            let tokensA = files[pair.locationA.fileIndex].normalizedTokens
            let tokensB = files[pair.locationB.fileIndex].normalizedTokens

            var startA = pair.locationA.offset
            var startB = pair.locationB.offset
            var endA = startA + pair.tokenCount
            var endB = startB + pair.tokenCount

            while startA > 0, startB > 0, tokensA[startA - 1].text == tokensB[startB - 1].text {
                startA -= 1
                startB -= 1
            }

            while endA < tokensA.count, endB < tokensB.count, tokensA[endA].text == tokensB[endB].text {
                endA += 1
                endB += 1
            }

            let expandedCount = endA - startA

            return ClonePair(
                locationA: TokenLocation(fileIndex: pair.locationA.fileIndex, offset: startA),
                locationB: TokenLocation(fileIndex: pair.locationB.fileIndex, offset: startB),
                tokenCount: expandedCount
            )
        }
    }

    private func classifyClones(
        _ pairs: [ClonePair],
        files: [FileTokens]
    ) -> [ClassifiedPair] {
        pairs.map { pair in
            let rawA = files[pair.locationA.fileIndex].tokens
            let rawB = files[pair.locationB.fileIndex].tokens

            let isExactMatch = tokensMatch(
                rawA, offsetA: pair.locationA.offset,
                rawB, offsetB: pair.locationB.offset,
                count: pair.tokenCount
            )

            return ClassifiedPair(
                type: isExactMatch ? .type1 : .type2,
                tokenCount: pair.tokenCount,
                locationA: pair.locationA,
                locationB: pair.locationB
            )
        }
    }

    private func deduplicateClones(_ pairs: [ClassifiedPair], files: [FileTokens]) -> [CloneGroup] {
        var uniquePairs: [ClassifiedPair] = []

        for pair in pairs {
            let isDuplicate = uniquePairs.contains { existing in
                isSubsumed(pair, by: existing) || isSubsumed(existing, by: pair)
            }

            if !isDuplicate {
                uniquePairs.append(pair)
            }
        }

        return uniquePairs.map { buildCloneGroup(from: $0, files: files) }
    }

    private func filterByMinimumLineCount(_ groups: [CloneGroup]) -> [CloneGroup] {
        groups.filter { $0.lineCount >= minimumLineCount }
    }
}

extension CloneDetector {

    private func tokensMatch(
        _ tokensA: [Token], offsetA: Int,
        _ tokensB: [Token], offsetB: Int,
        count: Int
    ) -> Bool {
        for index in 0 ..< count {
            guard
                tokensA[offsetA + index].text == tokensB[offsetB + index].text
            else {
                return false
            }
        }

        return true
    }

    private func isOverlapping(_ locationA: TokenLocation, _ locationB: TokenLocation) -> Bool {
        guard
            locationA.fileIndex == locationB.fileIndex
        else {
            return false
        }

        let distance = abs(locationA.offset - locationB.offset)
        return distance < minimumTokenCount
    }

    private func isSubsumed(_ pair: ClassifiedPair, by other: ClassifiedPair) -> Bool {
        let pairEndA = pair.locationA.offset + pair.tokenCount
        let pairEndB = pair.locationB.offset + pair.tokenCount
        let otherEndA = other.locationA.offset + other.tokenCount
        let otherEndB = other.locationB.offset + other.tokenCount

        let aSubsumed =
            pair.locationA.fileIndex == other.locationA.fileIndex
            && pair.locationA.offset >= other.locationA.offset
            && pairEndA <= otherEndA

        let bSubsumed =
            pair.locationB.fileIndex == other.locationB.fileIndex
            && pair.locationB.offset >= other.locationB.offset
            && pairEndB <= otherEndB

        return aSubsumed && bSubsumed
    }

    private func buildCloneGroup(from pair: ClassifiedPair, files: [FileTokens]) -> CloneGroup {
        let fragmentA = CloneGroupBuilder.buildFragment(
            file: files[pair.locationA.fileIndex].file,
            tokens: files[pair.locationA.fileIndex].tokens,
            startIndex: pair.locationA.offset,
            endIndex: pair.locationA.offset + pair.tokenCount - 1
        )
        let fragmentB = CloneGroupBuilder.buildFragment(
            file: files[pair.locationB.fileIndex].file,
            tokens: files[pair.locationB.fileIndex].tokens,
            startIndex: pair.locationB.offset,
            endIndex: pair.locationB.offset + pair.tokenCount - 1
        )

        let lineCount = max(
            fragmentA.endLine - fragmentA.startLine + 1,
            fragmentB.endLine - fragmentB.startLine + 1
        )

        return CloneGroup(
            type: pair.type,
            tokenCount: pair.tokenCount,
            lineCount: lineCount,
            similarity: 100.0,
            fragments: [fragmentA, fragmentB]
        )
    }
}
