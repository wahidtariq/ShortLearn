//
//  WikiSummary.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

struct WikiSummary: Decodable, Identifiable, Hashable {

    let title: String
    let extract: String
    let contentURLPage: URL
    let thumbnailURL: URL?
    let originalImageURL: URL?

    var id: String { contentURLPage.absoluteString }

    /// Best image for full-screen display. Prefers originalimage, falls back to thumbnail.
    var displayImageURL: URL? { originalImageURL ?? thumbnailURL }

    enum CodingKeys: String, CodingKey {
        case title, extract, thumbnail
        case originalImage = "originalimage"
        case contentURLs = "content_urls"
    }
    private enum ImageKeys: String, CodingKey { case source }
    private enum URLsKeys: String, CodingKey { case desktop }
    private enum DesktopKeys: String, CodingKey { case page }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        extract = try container.decode(String.self, forKey: .extract)

        if let thumb = try? container.nestedContainer(keyedBy: ImageKeys.self, forKey: .thumbnail) {
            thumbnailURL = try? thumb.decode(URL.self, forKey: .source)
        } else {
            thumbnailURL = nil
        }

        if let original = try? container.nestedContainer(keyedBy: ImageKeys.self, forKey: .originalImage) {
            originalImageURL = try? original.decode(URL.self, forKey: .source)
        } else {
            originalImageURL = nil
        }

        let urls = try container.nestedContainer(keyedBy: URLsKeys.self, forKey: .contentURLs)
        let desktop = try urls.nestedContainer(keyedBy: DesktopKeys.self, forKey: .desktop)
        contentURLPage = try desktop.decode(URL.self, forKey: .page)
    }
}
