//
//  MovieListService.swift
//  Services
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//
import Foundation
import NetworkLayer

public struct MovieListService: Sendable {
    let fetchListOfPopularMovies: @Sendable (
        _ page: Int
    ) async throws -> MovieListResponse

    /// Fetches a page of TMDB popular movies.
    public func popularMovies(page: Int = 1) async throws -> MovieListResponse {
        try await fetchListOfPopularMovies(page)
    }
}

extension MovieListService {
    public static func live(_ networkService: NetworkService) -> Self {
        .init(
            fetchListOfPopularMovies: { page in
                try await networkService.call(endpoint: .popularMovies(page: page))
            }
        )
    }

    public static func mock(popularMovies: MovieListResponse? = nil) -> Self {
        .init(
            fetchListOfPopularMovies: { _ in
                popularMovies ?? MovieListResponse(page: 1, results: [], totalPages: 0, totalResults: 0)
            }
        )
    }
}

#if DEBUG
extension MovieListService {
    /// A mock whose fetch always throws — for testing error paths.
    public static func failing(_ error: Error = URLError(.notConnectedToInternet)) -> Self {
        .init(fetchListOfPopularMovies: { _ in throw error })
    }
}
#endif
