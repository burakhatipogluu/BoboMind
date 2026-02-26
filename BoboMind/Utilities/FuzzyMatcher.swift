import Foundation

enum FuzzyMatcher {
    struct Match {
        let score: Int
    }

    /// Unicode-safe subsequence fuzzy match using Character arrays.
    /// Returns nil if no match; otherwise returns a score.
    static func match(pattern: String, in target: String) -> Match? {
        let patternChars = Array(pattern.lowercased())
        // Limit search to first 500 characters to avoid freeze on large clipboard items
        let targetString = target.count > 500 ? String(target.prefix(500)) : target
        let targetChars = Array(targetString.lowercased())

        guard !patternChars.isEmpty, !targetChars.isEmpty else { return nil }

        var score = 0
        var pIdx = 0
        var previousMatchIdx: Int? = nil

        let wordBoundaries: Set<Character> = [" ", "-", "_", ".", "/"]

        for tIdx in targetChars.indices {
            guard pIdx < patternChars.count else { break }

            guard patternChars[pIdx] == targetChars[tIdx] else { continue }

            // Base score
            score += 1

            // Consecutive match bonus
            if let prev = previousMatchIdx, prev == tIdx - 1 {
                score += 5
            }

            // Word boundary bonus
            if tIdx == 0 {
                score += 10
            } else if wordBoundaries.contains(targetChars[tIdx - 1]) {
                score += 10
            }

            previousMatchIdx = tIdx
            pIdx += 1
        }

        // All pattern characters must be matched
        guard pIdx == patternChars.count else { return nil }

        return Match(score: score)
    }
}
