//
//  Movie.swift
//  AppleTVMovieApp
//
//  Created by Halil Özel on 30.08.2019.
//  Copyright © 2019 Halil Özel. All rights reserved.
//

import Foundation

enum MovieRail: String, CaseIterable, Hashable, Sendable {
    case popular
    case topRated
    case nowPlaying
    case upcoming

    var title: String {
        switch self {
        case .popular:
            return "Popular"
        case .topRated:
            return "Top Rated"
        case .nowPlaying:
            return "Now Playing"
        case .upcoming:
            return "Upcoming"
        }
    }

    var endpoint: String {
        switch self {
        case .popular:
            return "popular"
        case .topRated:
            return "top_rated"
        case .nowPlaying:
            return "now_playing"
        case .upcoming:
            return "upcoming"
        }
    }
}

struct Movie: Decodable, Hashable, Sendable {
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
        TMDbImage.url(path: posterPath, size: "w780")
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

struct MoviePage: Decodable, Sendable {
    let results: [Movie]
}

struct CastMember: Decodable, Hashable, Sendable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case character
        case order
        case profilePath = "profile_path"
    }

    static func == (lhs: CastMember, rhs: CastMember) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var profileURL: URL? {
        TMDbImage.url(path: profilePath, size: "w342")
    }

    var characterText: String {
        character?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var accessibilitySummary: String {
        let role = characterText
        if role.isEmpty {
            return name
        }
        return "\(name), \(role)"
    }
}

struct CrewMember: Decodable, Hashable, Sendable {
    let id: Int
    let name: String
    let job: String?

    static func == (lhs: CrewMember, rhs: CrewMember) -> Bool {
        lhs.id == rhs.id && lhs.job == rhs.job
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(job)
    }
}

struct MovieCredits: Decodable, Sendable {
    let cast: [CastMember]
    let crew: [CrewMember]

    var directors: [String] {
        var seen = Set<Int>()
        return crew.compactMap { member -> String? in
            guard member.job == "Director" else { return nil }
            let name = member.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(member.id).inserted else { return nil }
            return name
        }
    }

    var directorLine: String? {
        let names = directors
        guard !names.isEmpty else { return nil }
        return "Directed by \(names.joined(separator: ", "))"
    }

    var billedCast: [CastMember] {
        var seen = Set<Int>()
        return cast
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .filter { member in
                let name = member.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return !name.isEmpty && seen.insert(member.id).inserted
            }
            .prefix(18)
            .map { $0 }
    }
}

enum TMDbImage {
    static func url(path: String?, size: String) -> URL? {
        guard let path else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(normalized)")
    }
}
