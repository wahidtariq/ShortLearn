//
//  FactCardView.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import SwiftUI

struct FactCardView: View {
    let summary: WikiSummary

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            gradientOverlay
            contentLayer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.title). \(summary.extract)")
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color.black
            .overlay {
                if summary.displayImageURL != nil || summary.thumbnailURL != nil {
                    ProgressiveImage(
                        primaryURL: summary.originalImageURL,
                        placeholderURL: summary.thumbnailURL
                    ) {
                        placeholderGradient
                    }
                } else {
                    placeholderGradient
                }
            }
            .clipped()
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.18, green: 0.14, blue: 0.42), Color(red: 0.42, green: 0.18, blue: 0.62)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.45),
                .clear,
                .black.opacity(0.55),
                .black.opacity(0.92)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)

            Text(summary.extract)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
                .lineLimit(8)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)

            Link(destination: summary.contentURLPage) {
                Text("Source: Wikipedia (CC BY-SA)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Loaded card") {
    let json = """
    {
      "title": "Cressida cressida",
      "extract": "Cressida cressida, the clearwing swallowtail, is a butterfly endemic to Australia. It is the only species in its genus.",
      "originalimage": {"source": "https://upload.wikimedia.org/wikipedia/commons/e/ee/Mounted_Cressida_cressida_male_and_female.jpg"},
      "thumbnail": {"source": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Mounted_Cressida_cressida_male_and_female.jpg/330px-Mounted_Cressida_cressida_male_and_female.jpg"},
      "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Cressida_cressida"}}
    }
    """
    let summary = try! JSONDecoder().decode(WikiSummary.self, from: Data(json.utf8))
    return FactCardView(summary: summary).preferredColorScheme(.dark)
}

#Preview("Long title, no image") {
    let json = """
    {
      "title": "2023 World Challenge Europe Endurance Cup for HRT Performance Drivers",
      "extract": "The 2023 World Challenge Europe Endurance Cup was the 13th edition of the GT World Challenge Europe Endurance Cup. The season consisted of five endurance races held across Europe, including the prestigious 24 Hours of Spa.",
      "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Sample"}}
    }
    """
    let summary = try! JSONDecoder().decode(WikiSummary.self, from: Data(json.utf8))
    return FactCardView(summary: summary).preferredColorScheme(.dark)
}
