//
//  MoviesService+Dependency.swift
//  MoviesService
//
//  Registers the movie-detail service with swift-dependencies.
//

import Dependencies
import Foundation

extension MoviesService: DependencyKey {
    public static var liveValue: MoviesService {
        @Dependency(\.networkService) var networkService
        return .live(networkService)
    }
    /// Safety net for tests: throws if used without an override (there is no
    /// release-safe `MovieDetail` sample to return). Real tests set their own mock.
    public static var testValue: MoviesService {
        .init(fetchMovieDetail: { _ in throw MoviesServiceError.unimplemented })
    }
    #if DEBUG
    /// Previews get the sample detail so the screen renders without a network.
    public static var previewValue: MoviesService { .mock(detail: .sample) }
    #endif
}

public extension DependencyValues {
    var moviesService: MoviesService {
        get { self[MoviesService.self] }
        set { self[MoviesService.self] = newValue }
    }
}

enum MoviesServiceError: Error {
    case unimplemented
}
