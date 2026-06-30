//
//  Movie.swift
//  Services
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//

/// A single movie entry within a ``MovieListResponse``.
public struct Movie: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let originalLanguage: String
    public let overview: String
    /// Relative path (e.g. `/abc.jpg`); `nil` when TMDB has no artwork. Prefix with the
    /// image base URL + size to build a full URL.
    public let posterPath: String?
    public let backdropPath: String?
    /// ISO `yyyy-MM-dd`; can be an empty string for unreleased titles.
    public let releaseDate: String
    public let genreIDs: [Int]
    public let popularity: Double
    public let voteAverage: Double
    public let voteCount: Int
    public let adult: Bool
    public let video: Bool

    public init(
        id: Int,
        title: String,
        originalTitle: String,
        originalLanguage: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String,
        genreIDs: [Int],
        popularity: Double,
        voteAverage: Double,
        voteCount: Int,
        adult: Bool,
        video: Bool
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.originalLanguage = originalLanguage
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.genreIDs = genreIDs
        self.popularity = popularity
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.adult = adult
        self.video = video
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case popularity
        case adult
        case video
        case originalTitle = "original_title"
        case originalLanguage = "original_language"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case genreIDs = "genre_ids"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
