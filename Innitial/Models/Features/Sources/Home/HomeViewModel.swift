//
//  HomeViewModel.swift
//  Features

import Foundation
import MovieListService

@MainActor
@Observable
public final class HomeViewModel {

    public private(set) var popular: [Movie] = []
    public private(set) var topRated: [Movie] = []
    public private(set) var upcoming: [Movie] = []
    public private(set) var nowPlaying: [Movie] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let movieListService: MovieListService
    private let imageBaseURL: String

    public init(movieListService: MovieListService, imageBaseURL: String) {
        self.movieListService = movieListService
        self.imageBaseURL = imageBaseURL
    }

    /// Loads every carousel's first page in parallel. Safe to call from `.task`:
    /// it no-ops while a load is already running.
    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let popular: Void = loadPopular()
        async let topRated: Void = loadTopRated()
        async let upcoming: Void = loadUpcoming()
        async let nowPlaying: Void = loadNowPlaying()
        _ = await (popular, topRated, upcoming, nowPlaying)
    }

    public func loadPopular() async {
        do { popular = try await movieListService.popularMovies().results }
        catch { errorMessage = error.localizedDescription }
    }

    public func loadTopRated() async {
        do { topRated = try await movieListService.topRatedMovies().results }
        catch { errorMessage = error.localizedDescription }
    }

    public func loadUpcoming() async {
        do { upcoming = try await movieListService.upcomingMovies().results }
        catch { errorMessage = error.localizedDescription }
    }

    public func loadNowPlaying() async {
        do { nowPlaying = try await movieListService.nowPlayingMovies().results }
        catch { errorMessage = error.localizedDescription }
    }

    /// Builds the poster URL for a movie: `<imageBaseURL>/<size><posterPath>`.
    /// Returns `nil` when the movie has no artwork or no base is configured.
    public func posterURL(for movie: Movie, size: String = "w500") -> URL? {
        guard let posterPath = movie.posterPath, !imageBaseURL.isEmpty else { return nil }
        return URL(string: imageBaseURL + "/" + size + posterPath)
    }
}
