//
//  MovieListService.swift
//  Services
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//
import Foundation
import NetworkLayer

public struct MovieListService: Sendable {
    let fetchListOfPopularMovies: @Sendable (_ page: Int) async throws -> MovieListResponse
    let fetchTopRatedMovies: @Sendable (_ page: Int) async throws -> MovieListResponse
    let fetchUpcomingMovies: @Sendable (_ page: Int) async throws -> MovieListResponse
    let fetchNowPlayingMovies: @Sendable (_ page: Int) async throws -> MovieListResponse

    /// Fetches a page of TMDB popular movies.
    public func popularMovies(page: Int = 1) async throws -> MovieListResponse {
        try await fetchListOfPopularMovies(page)
    }

    /// Fetches a page of TMDB top rated movies.
    public func topRatedMovies(page: Int = 1) async throws -> MovieListResponse {
        try await fetchTopRatedMovies(page)
    }

    /// Fetches a page of TMDB upcoming movies.
    public func upcomingMovies(page: Int = 1) async throws -> MovieListResponse {
        try await fetchUpcomingMovies(page)
    }

    /// Fetches a page of TMDB now playing movies.
    public func nowPlayingMovies(page: Int = 1) async throws -> MovieListResponse {
        try await fetchNowPlayingMovies(page)
    }
}

extension MovieListService {
    public static func live(_ networkService: NetworkService) -> Self {
        .init(
            fetchListOfPopularMovies: { page in
                try await networkService.call(endpoint: .popularMovies(page: page))
            },
            fetchTopRatedMovies: { page in
                try await networkService.call(endpoint: .topRatedMovies(page: page))
            },
            fetchUpcomingMovies: { page in
                try await networkService.call(endpoint: .upcomingMovies(page: page))
            },
            fetchNowPlayingMovies: { page in
                try await networkService.call(endpoint: .nowPlayingMovies(page: page))
            }
        )
    }

    public static func mock(
        popularMovies: MovieListResponse? = nil,
        topRatedMovies: MovieListResponse? = nil,
        upcomingMovies: MovieListResponse? = nil,
        nowPlayingMovies: MovieListResponse? = nil
    ) -> Self {
        let empty = MovieListResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
        return .init(
            fetchListOfPopularMovies: { _ in popularMovies ?? empty },
            fetchTopRatedMovies: { _ in topRatedMovies ?? empty },
            fetchUpcomingMovies: { _ in upcomingMovies ?? empty },
            fetchNowPlayingMovies: { _ in nowPlayingMovies ?? empty }
        )
    }
}

#if DEBUG
extension MovieListService {
    /// A mock whose every fetch always throws — for testing error paths.
    public static func failing(_ error: Error = URLError(.notConnectedToInternet)) -> Self {
        .init(
            fetchListOfPopularMovies: { _ in throw error },
            fetchTopRatedMovies: { _ in throw error },
            fetchUpcomingMovies: { _ in throw error },
            fetchNowPlayingMovies: { _ in throw error }
        )
    }
}
#endif
