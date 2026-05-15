//
//  WikiService.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

enum WikiServiceError: Error, Equatable {
    case badResponse
    case decodeFailed
}

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}

actor WikiService: ContentFetching {

    static let shared = WikiService()

    private let endpoint: URL
    private let userAgent: String
    private let bestOfCount: Int
    private let client: HTTPClient
    private let decoder: JSONDecoder

    init(
        endpoint: URL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/random/summary")!,
        userAgent: String = "ShortLearn/0.1 (https://github.com/example; contact@example.com)",
        bestOfCount: Int = 3,
        client: HTTPClient = URLSession(configuration: WikiService.defaultConfiguration()),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.endpoint = endpoint
        self.userAgent = userAgent
        self.bestOfCount = bestOfCount
        self.client = client
        self.decoder = decoder
    }

    private static func defaultConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = true
        return configuration
    }

    func nextCard() async throws -> WikiSummary {
        try await bestSummary(of: bestOfCount)
    }

    func randomSummary() async throws -> WikiSummary {
        var request = URLRequest(url: endpoint)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await client.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WikiServiceError.badResponse
        }
        do {
            return try decoder.decode(WikiSummary.self, from: data)
        } catch {
            throw WikiServiceError.decodeFailed
        }
    }

    func bestSummary(of count: Int) async throws -> WikiSummary {
        try await withThrowingTaskGroup(of: WikiSummary.self) { group in
            for _ in 0..<max(1, count) {
                group.addTask { try await self.randomSummary() }
            }
            var best: WikiSummary?
            var bestScore = Int.min
            for try await summary in group {
                let score = HookScorer.score(summary)
                if score > bestScore {
                    bestScore = score
                    best = summary
                }
            }
            guard let best else { throw WikiServiceError.badResponse }
            return best
        }
    }
}
