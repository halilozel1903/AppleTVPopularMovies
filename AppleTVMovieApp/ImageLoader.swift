//
//  ImageLoader.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import UIKit

enum ImageLoadError: Error {
    case invalidData
}

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 45
            self.session = URLSession(configuration: configuration)
        }
        cache.countLimit = 60
    }

    func image(for url: URL) async throws -> UIImage {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else {
            throw ImageLoadError.invalidData
        }
        cache.setObject(image, forKey: key)
        return image
    }
}
