//
//  ImagePrefetcher.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

protocol ImagePrefetching: Sendable {
    func prefetch(_ urls: [URL])
}

actor ImagePrefetcher: ImagePrefetching {
    static let shared = ImagePrefetcher()

    private var inFlight: Set<URL> = []
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func prefetch(_ urls: [URL]) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            for url in urls {
                await self.prefetchOne(url)
            }
        }
    }

    private func prefetchOne(_ url: URL) async {
        guard inFlight.insert(url).inserted else { return }
        defer { inFlight.remove(url) }

        var req = URLRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        req.setValue("ShortLearn/0.1", forHTTPHeaderField: "User-Agent")
        _ = try? await session.data(for: req)
    }
}
