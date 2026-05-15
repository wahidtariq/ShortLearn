//
//  FeedViewModel.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import SwiftUI

@Observable
@MainActor
final class FeedViewModel {

    private(set) var cards: [WikiSummary] = []
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    let prefetchBatch: Int
    let refillThreshold: Int
    let imagePrefetchWindow: Int

    private let fetcher: ContentFetching
    private let imagePrefetcher: ImagePrefetching

    init(
        fetcher: ContentFetching = WikiService.shared,
        imagePrefetcher: ImagePrefetching = ImagePrefetcher.shared,
        prefetchBatch: Int = 5,
        refillThreshold: Int = 3,
        imagePrefetchWindow: Int = 3
    ) {
        self.fetcher = fetcher
        self.imagePrefetcher = imagePrefetcher
        self.prefetchBatch = prefetchBatch
        self.refillThreshold = refillThreshold
        self.imagePrefetchWindow = imagePrefetchWindow
    }

    func loadInitial() async {
        guard cards.isEmpty else { return }
        await loadMore()
    }

    func cardAppeared(_ card: WikiSummary) {
        guard let index = cards.firstIndex(of: card) else { return }
        prefetchImages(startingAt: index + 1)
        let remaining = cards.count - 1 - index
        if remaining <= refillThreshold {
            Task { await loadMore() }
        }
    }

    private func prefetchImages(startingAt startIndex: Int) {
        let endIndex = min(startIndex + imagePrefetchWindow, cards.count)
        guard startIndex < endIndex else { return }
        let urls = cards[startIndex..<endIndex].compactMap { card -> URL? in
            card.displayImageURL ?? card.thumbnailURL
        }
        if !urls.isEmpty {
            imagePrefetcher.prefetch(urls)
        }
    }

    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let batch = try await withThrowingTaskGroup(of: WikiSummary.self) { group in
                for _ in 0..<prefetchBatch {
                    group.addTask { try await self.fetcher.nextCard() }
                }
                var collected: [WikiSummary] = []
                for try await summary in group { collected.append(summary) }
                return collected
            }
            var seen = Set(cards.map(\.id))
            var unique: [WikiSummary] = []
            for card in batch where seen.insert(card.id).inserted {
                unique.append(card)
            }
            let firstNewIndex = cards.count
            cards.append(contentsOf: unique)
            errorMessage = nil
            prefetchImages(startingAt: firstNewIndex)
        } catch {
            errorMessage = "Failed to load the feed please try again."
        }
    }
}
