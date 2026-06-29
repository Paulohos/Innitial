//
//  MoviesService.swift
//  Services
//
//  Created by Paulo Henrique Oliveira Souza on 29/06/26.
//

import Foundation
import NetworkLayer

public struct MoviesService: Sendable {
    let fetchMovieDetail: @Sendable (_ id: Int) async throws -> MovieDetail

    /// Fetches the full details of a movie (TMDB `/movie/{id}`).
    public func movieDetail(id: Int) async throws -> MovieDetail {
        try await fetchMovieDetail(id)
    }
}

extension MoviesService {
    public static func live(_ networkService: NetworkService) -> Self {
        .init(
            fetchMovieDetail: { id in
                try await networkService.call(endpoint: .movieDetails(id: id))
            }
        )
    }

    public static func mock(detail: MovieDetail) -> Self {
        .init(fetchMovieDetail: { _ in detail })
    }
}

#if DEBUG
extension MoviesService {
    /// A mock whose fetch always throws — for testing error paths.
    public static func failing(_ error: Error = URLError(.notConnectedToInternet)) -> Self {
        .init(fetchMovieDetail: { _ in throw error })
    }
}
#endif
