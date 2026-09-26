//
//  MovieService.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import Foundation

enum MovieServiceError: LocalizedError, Sendable {
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

struct MovieService: Sendable {
    let session: URLSession
    let apiKey: String
    let baseURL: URL

    init(
        session: URLSession? = nil,
        apiKey: String = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String ?? "",
        baseURL: URL = URL(string: "https://api.themoviedb.org/3")!
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
        self.baseURL = baseURL
    }

    func movies(in rail: MovieRail) async throws -> [Movie] {
        let url = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(rail.endpoint)
        return try await decode(MoviePage.self, from: try await fetch(url)).results
    }

    func popularMovies() async throws -> [Movie] {
        try await movies(in: .popular)
    }

    func movieDetails(id: Int) async throws -> Movie {
        try await decode(Movie.self, from: try await fetch(try movieURL(id: id)))
    }

    func credits(for id: Int) async throws -> MovieCredits {
        try await decode(MovieCredits.self, from: try await fetch(try movieURL(id: id, suffix: "credits")))
    }

    func similarMovies(to id: Int) async throws -> [Movie] {
        try await decode(MoviePage.self, from: try await fetch(try movieURL(id: id, suffix: "similar"))).results
    }

    private func movieURL(id: Int, suffix: String? = nil) throws -> URL {
        guard id > 0 else {
            throw MovieServiceError.invalidResponse
        }
        var url = baseURL
            .appendingPathComponent("movie")
            .appendingPathComponent(String(id))
        if let suffix {
            url.appendPathComponent(suffix)
        }
        return url
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
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
