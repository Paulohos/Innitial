//
//  MovieListService+Dependency.swift
//  MovieListService
//
//  Registers the movie-list service with swift-dependencies.
//

import Dependencies

extension MovieListService: DependencyKey {
    public static var liveValue: MovieListService {
        @Dependency(\.networkService) var networkService
        return .live(networkService)
    }
    /// Safety net for tests: empty results. Real tests override per case.
    public static var testValue: MovieListService { .mock() }
    #if DEBUG
    /// Previews get the sample data so carousels render without a network.
    public static var previewValue: MovieListService {
        .mock(
            popularMovies: .sample,
            topRatedMovies: .sample,
            upcomingMovies: .sample,
            nowPlayingMovies: .sample
        )
    }
    #endif
}

public extension DependencyValues {
    var movieListService: MovieListService {
        get { self[MovieListService.self] }
        set { self[MovieListService.self] = newValue }
    }
}
