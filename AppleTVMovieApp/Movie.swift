//
//  Movie.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import Foundation

struct Movie: Decodable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }

    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var posterURL: URL? {
        guard let posterPath, !posterPath.isEmpty else { return nil }
        let path = posterPath.hasPrefix("/") ? posterPath : "/\(posterPath)"
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var releaseYear: String? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        let year = releaseDate.prefix(4)
        guard year.allSatisfy(\.isNumber) else { return nil }
        return String(year)
    }

    var ratingText: String? {
        guard let voteAverage, voteAverage > 0 else { return nil }
        return String(format: "★ %.1f", voteAverage)
    }

    var metaText: String {
        [releaseYear, ratingText].compactMap { $0 }.joined(separator: "    ")
    }

    var overviewText: String {
        let trimmed = overview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "No overview available." : trimmed
    }

    var accessibilitySummary: String {
        [title, releaseYear].compactMap { $0 }.joined(separator: ", ")
    }
}

struct PopularMoviesPage: Decodable {
    let results: [Movie]
}
