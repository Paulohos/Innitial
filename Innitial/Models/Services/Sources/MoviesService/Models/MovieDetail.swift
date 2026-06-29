//
//  MovieDetail.swift
//  Services
//

/// Full details of a single movie, from TMDB `/movie/{id}`.
public struct MovieDetail: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let originalTitle: String
    public let originalLanguage: String
    public let overview: String
    public let tagline: String
    public let status: String
    public let homepage: String?
    public let imdbID: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String
    public let runtime: Int?
    public let budget: Int
    public let revenue: Int
    public let popularity: Double
    public let voteAverage: Double
    public let voteCount: Int
    public let adult: Bool
    public let video: Bool
    public let genres: [Genre]
    public let productionCompanies: [ProductionCompany]
    public let productionCountries: [ProductionCountry]
    public let spokenLanguages: [SpokenLanguage]
    public let originCountry: [String]
    /// Present when the movie is part of a franchise (e.g. "Star Wars Collection"); `nil` otherwise.
    public let belongsToCollection: Collection?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, tagline, status, homepage, runtime, budget, revenue, popularity, adult, video, genres
        case originalTitle = "original_title"
        case originalLanguage = "original_language"
        case imdbID = "imdb_id"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case spokenLanguages = "spoken_languages"
        case originCountry = "origin_country"
        case belongsToCollection = "belongs_to_collection"
    }

    public struct Genre: Decodable, Hashable, Identifiable, Sendable {
        public let id: Int
        public let name: String
    }

    public struct ProductionCompany: Decodable, Hashable, Identifiable, Sendable {
        public let id: Int
        public let name: String
        public let logoPath: String?
        public let originCountry: String

        enum CodingKeys: String, CodingKey {
            case id, name
            case logoPath = "logo_path"
            case originCountry = "origin_country"
        }
    }

    public struct ProductionCountry: Decodable, Hashable, Sendable {
        public let iso31661: String
        public let name: String

        enum CodingKeys: String, CodingKey {
            case iso31661 = "iso_3166_1"
            case name
        }
    }

    public struct SpokenLanguage: Decodable, Hashable, Sendable {
        public let englishName: String
        public let iso6391: String
        public let name: String

        enum CodingKeys: String, CodingKey {
            case englishName = "english_name"
            case iso6391 = "iso_639_1"
            case name
        }
    }

    public struct Collection: Decodable, Hashable, Identifiable, Sendable {
        public let id: Int
        public let name: String
        public let posterPath: String?
        public let backdropPath: String?

        enum CodingKeys: String, CodingKey {
            case id, name
            case posterPath = "poster_path"
            case backdropPath = "backdrop_path"
        }
    }
}
