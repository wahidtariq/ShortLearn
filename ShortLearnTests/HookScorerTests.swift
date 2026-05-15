//
//  HookScorerTests.swift
//  ShortLearnTests
//
//  Created by wahid tariq on 15/05/26.
//

import XCTest
@testable import ShortLearn

final class HookScorerTests: XCTestCase {

    private func makeSummary(
        title: String = "Sample",
        extract: String,
        thumbnail: URL? = URL(string: "https://example.com/img.jpg")
    ) -> WikiSummary {
        let json = """
        {
          "title": "\(title)",
          "extract": "\(extract)",
          \(thumbnail != nil ? "\"thumbnail\":{\"source\":\"\(thumbnail!.absoluteString)\"}," : "")
          "content_urls":{"desktop":{"page":"https://en.wikipedia.org/wiki/\(title.replacingOccurrences(of: " ", with: "_"))"}}
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(WikiSummary.self, from: json)
    }

    func test_extractInIdealLengthRange_addsThreePoints() {
        let s = makeSummary(extract: String(repeating: "a", count: 100), thumbnail: nil)
        // Length 100 → +3. No keyword, no thumbnail → 0. Total = 3.
        XCTAssertEqual(HookScorer.score(s), 3)
    }

    func test_extractTooShort_doesNotGetLengthBonus() {
        let s = makeSummary(extract: "Short.", thumbnail: nil)
        XCTAssertEqual(HookScorer.score(s), 0)
    }

    func test_extractMediumLength_getsSmallBonus() {
        let s = makeSummary(extract: String(repeating: "a", count: 60), thumbnail: nil)
        XCTAssertEqual(HookScorer.score(s), 1)
    }

    func test_hookKeyword_addsTwoPoints() {
        let extract = String(repeating: "x", count: 100) + " the first ever recorded"
        let s = makeSummary(extract: extract, thumbnail: nil)
        // +3 length, +2 keyword "first"
        XCTAssertEqual(HookScorer.score(s), 5)
    }

    func test_thumbnail_addsTwoPoints() {
        let s = makeSummary(extract: String(repeating: "a", count: 100))
        // +3 length, +2 thumbnail
        XCTAssertEqual(HookScorer.score(s), 5)
    }

    func test_disambiguationTitle_penalizesFivePoints() {
        let s = makeSummary(
            title: "Mercury disambiguation",
            extract: String(repeating: "a", count: 100),
            thumbnail: nil
        )
        // +3 length, -5 disambiguation = -2
        XCTAssertEqual(HookScorer.score(s), -2)
    }

    func test_listOfTitle_penalizesFivePoints() {
        let s = makeSummary(
            title: "List of countries",
            extract: String(repeating: "a", count: 100),
            thumbnail: nil
        )
        XCTAssertEqual(HookScorer.score(s), -2)
    }

    func test_idealCard_getsMaxScore() {
        let extract = "The only species that " + String(repeating: "x", count: 80)
        let s = makeSummary(title: "Cool fact", extract: extract)
        // +3 length, +2 "only", +2 thumbnail = 7
        XCTAssertEqual(HookScorer.score(s), 7)
    }
}
