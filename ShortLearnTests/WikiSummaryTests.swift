//
//  WikiSummaryTests.swift
//  ShortLearnTests
//
//  Created by wahid tariq on 15/05/26.
//

import XCTest
@testable import ShortLearn

final class WikiSummaryTests: XCTestCase {

    func test_decodesValidPayload_withThumbnail() throws {
        let json = """
        {
          "title": "Cressida cressida",
          "extract": "A butterfly found in Australia.",
          "thumbnail": {"source": "https://upload.wikimedia.org/img.jpg", "width": 330, "height": 436},
          "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Cressida_cressida"}}
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(WikiSummary.self, from: json)

        XCTAssertEqual(summary.title, "Cressida cressida")
        XCTAssertEqual(summary.extract, "A butterfly found in Australia.")
        XCTAssertEqual(summary.thumbnailURL?.absoluteString, "https://upload.wikimedia.org/img.jpg")
        XCTAssertEqual(summary.contentURLPage.absoluteString, "https://en.wikipedia.org/wiki/Cressida_cressida")
    }

    func test_decodesValidPayload_withoutThumbnail() throws {
        let json = """
        {
          "title": "Quiet thing",
          "extract": "Nothing visual.",
          "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Quiet_thing"}}
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(WikiSummary.self, from: json)

        XCTAssertNil(summary.thumbnailURL)
        XCTAssertEqual(summary.title, "Quiet thing")
    }

    func test_decode_missingContentURLs_throws() {
        let json = """
        {
          "title": "Broken",
          "extract": "No urls."
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(WikiSummary.self, from: json))
    }

    func test_id_equalsContentURLPageString() throws {
        let json = """
        {
          "title": "X",
          "extract": "Y",
          "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/X"}}
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(WikiSummary.self, from: json)
        XCTAssertEqual(summary.id, "https://en.wikipedia.org/wiki/X")
    }
}
