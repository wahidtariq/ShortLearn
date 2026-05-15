//
//  ProgressiveImage.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import SwiftUI

/// Loads `primaryURL` (originalimage) but shows `placeholderURL` (thumbnail) immediately
/// while primary downloads. Auto-retries up to `maxAttempts - 1` times on transient failure.
/// Falls back to placeholder when primary exhausts retries.
struct ProgressiveImage<Fallback: View>: View {
    let primaryURL: URL?
    let placeholderURL: URL?
    @ViewBuilder let fallback: () -> Fallback

    private let maxAttempts = 2
    private let retryDelay: Duration = .milliseconds(600)

    @State private var attempt = 0

    var body: some View {
        ZStack {
            placeholderLayer
            primaryLayer
        }
    }

    @ViewBuilder
    private var placeholderLayer: some View {
        if let placeholderURL {
            AsyncImage(url: placeholderURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .empty, .failure:
                    fallback()
                @unknown default:
                    fallback()
                }
            }
        } else {
            fallback()
        }
    }

    @ViewBuilder
    private var primaryLayer: some View {
        if let primaryURL, attempt < maxAttempts {
            AsyncImage(
                url: primaryURL,
                transaction: Transaction(animation: .easeIn(duration: 0.25))
            ) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .empty:
                    Color.clear
                case .failure:
                    Color.clear.task(id: attempt) {
                        try? await Task.sleep(for: retryDelay)
                        if !Task.isCancelled {
                            attempt += 1
                        }
                    }
                @unknown default:
                    Color.clear
                }
            }
            .id(attempt)
        }
    }
}
