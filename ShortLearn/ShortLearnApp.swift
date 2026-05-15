//
//  ShortLearnApp.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import SwiftUI

@main
struct ShortLearnApp: App {
    init() {
        ImageCacheConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            FeedView()
                .preferredColorScheme(.dark)
        }
    }
}
