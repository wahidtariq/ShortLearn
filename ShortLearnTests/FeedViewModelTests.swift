//
//  FeedViewModelTests.swift
//  ShortLearnTests
//
//  Created by wahid tariq on 15/05/26.
//

import XCTest
@testable import ShortLearn

@MainActor
final class FeedViewModelTests: XCTestCase {

    // MARK: - Test Doubles

    final class StubFetcher: ContentFetching, @unchecked Sendable {
        var queue: [Result<WikiSummary, Error>]
        private(set) var callCount = 0
        private let lock = NSLock()

        init(queue: [Result<WikiSummary, Error>]) {
            self.queue = queue
        }

        func nextCard() async throws -> WikiSummary {
            lock.lock()
            defer { lock.unlock() }
            callCount += 1
            guard !queue.isEmpty else {
                throw WikiServiceError.badResponse
            }
            return try queue.removeFirst().get()
        }
    }

    private func sample(
        id: String,
        extract: String = "Some extract.",
        imageURL: String? = nil
    ) -> WikiSummary {
        let resolvedURL = imageURL ?? "https://example.com/\(id).jpg"
        let imageBlock = "\"originalimage\":{\"source\":\"\(resolvedURL)\"},"
        let json = """
        {
          "title": "\(id)",
          "extract": "\(extract)",
          \(imageBlock)
          "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/\(id)"}}
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(WikiSummary.self, from: json)
    }

    final class SpyPrefetcher: ImagePrefetching, @unchecked Sendable {
        private let lock = NSLock()
        private var _calls: [[URL]] = []
        var calls: [[URL]] {
            lock.lock(); defer { lock.unlock() }
            return _calls
        }
        func prefetch(_ urls: [URL]) {
            lock.lock(); defer { lock.unlock() }
            _calls.append(urls)
        }
    }

    // MARK: - Tests

    func test_loadInitial_populatesCards() async {
        let cards = (1...5).map { sample(id: "Card_\($0)") }
        let fetcher = StubFetcher(queue: cards.map { .success($0) })
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 5, refillThreshold: 3)

        await vm.loadInitial()

        XCTAssertEqual(vm.cards.count, 5)
        XCTAssertEqual(fetcher.callCount, 5)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadInitial_doesNothing_whenAlreadyLoaded() async {
        let fetcher = StubFetcher(queue: (1...10).map { .success(sample(id: "C\($0)")) })
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 5, refillThreshold: 3)

        await vm.loadInitial()
        let countAfterFirst = fetcher.callCount

        await vm.loadInitial()

        XCTAssertEqual(fetcher.callCount, countAfterFirst)
        XCTAssertEqual(vm.cards.count, 5)
    }

    func test_loadMore_setsErrorMessage_onFailure() async {
        let fetcher = StubFetcher(queue: [.failure(WikiServiceError.badResponse)])
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 1, refillThreshold: 0)

        await vm.loadMore()

        XCTAssertTrue(vm.cards.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_loadMore_clearsError_onSubsequentSuccess() async {
        let fetcher = StubFetcher(queue: [.failure(WikiServiceError.badResponse)])
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 1, refillThreshold: 0)

        await vm.loadMore()
        XCTAssertNotNil(vm.errorMessage)

        fetcher.queue = [.success(sample(id: "Recovered"))]
        await vm.loadMore()

        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.cards.count, 1)
    }

    func test_loadMore_dedupesCardsByID() async {
        let duplicate = sample(id: "Same")
        let fetcher = StubFetcher(queue: [.success(duplicate), .success(duplicate)])
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 2, refillThreshold: 0)

        await vm.loadMore()

        XCTAssertEqual(vm.cards.count, 1)
    }

    func test_cardAppeared_triggersRefill_whenNearEnd() async {
        let initial = (1...5).map { sample(id: "Initial_\($0)") }
        let refill = (1...5).map { sample(id: "Refill_\($0)") }
        let fetcher = StubFetcher(queue: (initial + refill).map { .success($0) })
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 5, refillThreshold: 3)

        await vm.loadInitial()
        XCTAssertEqual(vm.cards.count, 5)

        // Trigger refill — card at index 2 has 2 cards remaining after, < threshold 3
        let triggerCard = vm.cards[2]
        vm.cardAppeared(triggerCard)

        // Wait for async refill task
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(vm.cards.count, 10)
    }

    func test_loadMore_triggersImagePrefetch_forNewCards() async {
        let cards = (1...3).map { sample(id: "C_\($0)") }
        let fetcher = StubFetcher(queue: cards.map { .success($0) })
        let spy = SpyPrefetcher()
        let vm = FeedViewModel(
            fetcher: fetcher,
            imagePrefetcher: spy,
            prefetchBatch: 3,
            refillThreshold: 0,
            imagePrefetchWindow: 5
        )

        await vm.loadInitial()

        XCTAssertFalse(spy.calls.isEmpty, "Expected prefetch call after loadMore")
        let prefetchedURLs = spy.calls.flatMap { $0 }
        XCTAssertEqual(Set(prefetchedURLs).count, 3)
    }

    func test_cardAppeared_prefetchesUpcomingImages() async {
        let cards = (1...6).map { sample(id: "C_\($0)") }
        let fetcher = StubFetcher(queue: cards.map { .success($0) })
        let spy = SpyPrefetcher()
        let vm = FeedViewModel(
            fetcher: fetcher,
            imagePrefetcher: spy,
            prefetchBatch: 6,
            refillThreshold: 0,
            imagePrefetchWindow: 2
        )

        await vm.loadInitial()
        let callsAfterLoad = spy.calls.count

        vm.cardAppeared(vm.cards[0])

        XCTAssertEqual(spy.calls.count, callsAfterLoad + 1)
        XCTAssertEqual(spy.calls.last?.count, 2, "Should prefetch next 2 images")
    }

    func test_cardAppeared_doesNotRefill_whenFarFromEnd() async {
        let cards = (1...10).map { sample(id: "C_\($0)") }
        let fetcher = StubFetcher(queue: cards.map { .success($0) })
        let vm = FeedViewModel(fetcher: fetcher, prefetchBatch: 10, refillThreshold: 3)

        await vm.loadInitial()
        let callsAfterLoad = fetcher.callCount

        // Card at index 0 has 9 remaining — well above threshold
        vm.cardAppeared(vm.cards[0])

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(fetcher.callCount, callsAfterLoad)
    }
}
