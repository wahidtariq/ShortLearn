//
//  FeedView.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import SwiftUI

struct FeedView: View {
    @State private var viewModel: FeedViewModel

    @MainActor
    init(viewModel: FeedViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? FeedViewModel())
    }

    var body: some View {
        Group {
            if viewModel.cards.isEmpty {
                loadingState
            } else {
                feed
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.caption)
                    .padding(8)
                    .background(.black, in: RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(.white)
                    .padding(.top, 60)
            }
        }
        .task { await viewModel.loadInitial() }
    }

    private var loadingState: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().tint(.white)
                Text("Fetching first hook…")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Loading first fact")
        }
    }

    private var feed: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.cards) { card in
                    FactCardView(summary: card)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .onAppear { viewModel.cardAppeared(card) }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
    }
}

#Preview {
    FeedView().preferredColorScheme(.dark)
}
