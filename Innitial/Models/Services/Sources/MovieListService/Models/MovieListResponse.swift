//
//  MovieListResponse.swift
//  Services
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//

/// A page of movies returned by TMDB list endpoints (popular, now playing, upcoming…).
public struct MovieListResponse: Decodable, Hashable, Identifiable, Sendable {
    public let page: Int
    public let results: [Movie]
    public let totalPages: Int
    public let totalResults: Int
    /// Present on date-bounded endpoints (e.g. now playing / upcoming); `nil` for popular.
    public let dates: Dates?

    /// The page number doubles as a stable identity for `ForEach` over multiple pages.
    public var id: Int { page }

    public init(
        page: Int,
        results: [Movie],
        totalPages: Int,
        totalResults: Int,
        dates: Dates? = nil
    ) {
        self.page = page
        self.results = results
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.dates = dates
    }

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
        case dates
    }

    /// The release-date window covered by the page (ISO `yyyy-MM-dd` strings).
    public struct Dates: Decodable, Hashable, Sendable {
        public let maximum: String
        public let minimum: String

        public init(maximum: String, minimum: String) {
            self.maximum = maximum
            self.minimum = minimum
        }
    }
}
