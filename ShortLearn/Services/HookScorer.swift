//
//  HookScorer.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

enum HookScorer {

    static let hookKeywords: [String] = [
        "only", "first", "largest", "smallest", "oldest",
        "why ", "how ", "never", "always"
    ]

    static let titleBlocklistContains = "disambiguation"
    static let titleBlocklistPrefix = "list of"

    static func score(_ summary: WikiSummary) -> Int {
        var score = 0
        let length = summary.extract.count
        if (80...250).contains(length) {
            score += 3
        } else if length > 50 {
            score += 1
        }

        let lowercasedExtract = summary.extract.lowercased()
        if hookKeywords.contains(where: { lowercasedExtract.contains($0) }) {
            score += 2
        }

        if summary.thumbnailURL != nil {
            score += 2
        }

        let lowercasedTitle = summary.title.lowercased()
        if lowercasedTitle.contains(titleBlocklistContains) || lowercasedTitle.hasPrefix(titleBlocklistPrefix) {
            score -= 5
        }

        return score
    }
}
