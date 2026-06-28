//
//  HomeViewModel.swift
//  Features

import Foundation
import MovieListService

@MainActor
@Observable
public final class HomeViewModel {

    public private(set) var movies: [Movie] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let movieListService: MovieListService
    private let imageBaseURL: String

    public init(movieListService: MovieListService, imageBaseURL: String) {
        self.movieListService = movieListService
        self.imageBaseURL = imageBaseURL
    }

    /// Builds the poster URL for a movie: `<imageBaseURL>/<size><posterPath>`.
    /// Returns `nil` when the movie has no artwork or no base is configured.
    public func posterURL(for movie: Movie, size: String = "w500") -> URL? {
        guard let posterPath = movie.posterPath, !imageBaseURL.isEmpty else { return nil }
        return URL(string: imageBaseURL + "/" + size + posterPath)
    }

    /// Loads the first page of popular movies. Safe to call from `.task`:
    /// it no-ops while a load is already running.
    public func loadPopularMovies() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            movies = try await movieListService.popularMovies().results
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
