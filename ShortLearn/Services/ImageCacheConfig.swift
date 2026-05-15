//
//  ImageCacheConfig.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

enum ImageCacheConfig {
    /// Configure URLCache.shared with generous limits so AsyncImage / URLSession requests
    /// can serve already-fetched images instantly. Call once at app launch.
    static func configure() {
        let memoryMB = 50
        let diskMB = 500
        URLCache.shared = URLCache(
            memoryCapacity: memoryMB * 1_024 * 1_024,
            diskCapacity: diskMB * 1_024 * 1_024,
            diskPath: "ShortLearnImageCache"
        )
    }
}
