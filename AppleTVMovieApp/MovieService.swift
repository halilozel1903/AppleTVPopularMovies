//
//  MovieService.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import Foundation

enum MovieServiceError: LocalizedError {
    case missingAPIKey
    case server(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add a TMDb API key to TMDBAPIKey in Info.plist."
        case .server(let statusCode):
            return "The movie service returned an error (\(statusCode))."
        case .invalidResponse:
            return "The movie data couldn't be read."
        }
    }
}

struct MovieService {
    var session: URLSession
    var apiKey: String
    var popularURL: URL

    init(
        session: URLSession? = nil,
        apiKey: String = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String ?? "",
        popularURL: URL = URL(string: "https://api.themoviedb.org/3/movie/popular")!
    ) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 45
            self.session = URLSession(configuration: configuration)
        }
        self.apiKey = apiKey
        self.popularURL = popularURL
    }

    func popularMovies() async throws -> [Movie] {
        let data = try await fetch(popularURL)
        do {
            return try JSONDecoder().decode(PopularMoviesPage.self, from: data).results
        } catch {
            throw MovieServiceError.invalidResponse
        }
    }

    func movieDetails(id: Int) async throws -> Movie {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)") else {
            throw MovieServiceError.invalidResponse
        }
        let data = try await fetch(url)
        do {
            return try JSONDecoder().decode(Movie.self, from: data)
        } catch {
            throw MovieServiceError.invalidResponse
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw MovieServiceError.missingAPIKey
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw MovieServiceError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: trimmedKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        guard let authorizedURL = components.url else {
            throw MovieServiceError.invalidResponse
        }

        let (data, response) = try await session.data(from: authorizedURL)
        guard let http = response as? HTTPURLResponse else {
            throw MovieServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw MovieServiceError.server(statusCode: http.statusCode)
        }
        return data
    }
}
