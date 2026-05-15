# ShortLearn

A free, ad-free iOS app that replaces endless YouTube Shorts / TikTok scroll with bite-sized learning cards. Swipe vertically through interesting facts from Wikipedia — each card is curated for "hook in the first line."

> Built as a weekend project to prove you can ship a Shorts-killer using only free public APIs and a lean SwiftUI stack.

---

## Features

- **TikTok-style vertical feed** — full-screen cards, snap-to-page scrolling, infinite refill
- **Hook-scored content** — best-of-N picker favors short, vivid, image-backed Wikipedia summaries; filters out disambiguation pages and lists
- **Progressive image loading** — low-res thumbnail shown immediately, full-res fades in once loaded
- **Aggressive prefetching** — next 3 image URLs warmed into `URLCache` before user scrolls
- **Auto-retry on failure** — one transparent retry per broken image; graceful gradient fallback
- **Offline-friendly cache** — `URLCache.shared` configured at 50 MB memory / 500 MB disk
- **Accessibility** — cards grouped for VoiceOver, loading state labeled, source link reachable
- **No backend, no auth, no tracking** — every API call is direct client → Wikipedia REST

---

## Screenshots

| App icon | Feed card |
|---|---|
| Pink/purple gradient with white spark glyph | Full-bleed image, title, extract, source attribution |

(Drop screenshots into `docs/` and link them here when you push.)

---

## Architecture

MVVM with protocol-based dependency injection. iOS 17+ `@Observable` state. No third-party dependencies.

```
ShortLearn/
├── ShortLearnApp.swift          # @main, boots ImageCacheConfig
├── Info.plist                   # UILaunchScreen wired to asset
├── Models/
│   └── WikiSummary.swift        # Codable model, derived id from URL
├── Services/
│   ├── ContentFetching.swift    # protocol: nextCard() async throws -> WikiSummary
│   ├── WikiService.swift        # actor, hits Wikipedia REST, best-of-N scoring
│   ├── HookScorer.swift         # pure scoring logic (length, keywords, blocklist)
│   ├── ImageCacheConfig.swift   # boot-time URLCache setup
│   └── ImagePrefetcher.swift    # actor, warms URLCache for upcoming cards
├── ViewModel/
│   └── FeedViewModel.swift      # @Observable @MainActor, owns cards/errors/state
└── Views/
    ├── FeedView.swift           # vertical paging feed
    ├── FactCardView.swift       # individual card layout
    └── ProgressiveImage.swift   # thumbnail → full-res with retry
```

### Data flow

```
ShortLearnApp
    └─ FeedView
        └─ FeedViewModel  ── ContentFetching ──▶ WikiService ──▶ Wikipedia REST
                          ── ImagePrefetching ─▶ ImagePrefetcher ──▶ URLCache.shared
```

### Why these choices

- **`@Observable` over `ObservableObject`** — finer-grained view invalidation, no `@Published` boilerplate
- **`actor WikiService`** — thread-safe network access without locks
- **Protocols for every collaborator** — every service injectable for tests; production wires `.shared` singletons
- **No `GeometryReader`** — `containerRelativeFrame([.horizontal, .vertical])` sizes cards to scroll container; iOS 17 native
- **`scrollTargetBehavior(.paging)`** — native paging, no rotated-TabView hack

---

## Requirements

- Xcode 15+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — project is generated from `project.yml`

---

## Build & run

```bash
git clone <repo-url>
cd ShortLearn
xcodegen generate
open ShortLearn.xcodeproj
```

Hit **⌘R**. Default target is iPhone simulator on iOS 17+.

### Headless build & test

```bash
xcodebuild test \
  -project ShortLearn.xcodeproj \
  -scheme ShortLearn \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO
```

---

## Tests

21 unit tests covering:

| Suite | Coverage |
|---|---|
| `WikiSummaryTests` | JSON decode happy path, missing thumbnail, missing content_urls, derived id |
| `HookScorerTests` | Each scoring rule isolated — length bands, keyword bonus, thumbnail bonus, blocklist penalty |
| `FeedViewModelTests` | Load/refill/dedupe/error recovery + image prefetch trigger windows |

Test doubles (`StubFetcher`, `SpyPrefetcher`) conform to production protocols — no mocking framework needed.

---

## Hook scoring

Each Wikipedia random summary is scored before being shown:

| Signal | Points |
|---|---|
| Extract length in 80–250 chars | +3 |
| Extract length 50–80 chars | +1 |
| Contains hook keyword (`only`, `first`, `largest`, `why `, etc.) | +2 |
| Has thumbnail | +2 |
| Title contains `disambiguation` or starts with `list of` | -5 |

`WikiService.bestSummary(of: N)` fetches N candidates in parallel and returns the highest-scoring one.

---

## Content sources

- **Wikipedia REST API** — `https://en.wikipedia.org/api/rest_v1/page/random/summary` — no auth required
- Attribution: all cards link back to the article. Wikipedia content is **CC BY-SA**.

Planned (not yet wired):
- Reddit r/todayilearned JSON
- Numbers API
- NASA APOD (daily pinned card)

---

## Roadmap

- [x] Weekend 1 — Wikipedia spike + card view
- [x] Weekend 2 — Vertical paging feed, prefetch buffer
- [x] Weekend 3 — Hook scoring, MVVM refactor, unit tests
- [x] Image cache + prefetcher + progressive load + retry
- [x] App icon + launch screen
- [ ] Reddit TIL + Numbers API behind same `ContentFetching` protocol
- [ ] NASA APOD daily pinned card
- [ ] Bookmark / save with SwiftData
- [ ] Daily local push notification
- [ ] Personalization toggle (Science / History / Tech / Space / Geography)
- [ ] Quiz mode using Open Trivia DB

---

## License

MIT. Wikipedia content used under CC BY-SA — always attributed in-app via clickable source link on every card.

---

## Acknowledgements

- Wikipedia / Wikimedia Foundation for the open API
- Anyone tired of YouTube Shorts who wanted something better
