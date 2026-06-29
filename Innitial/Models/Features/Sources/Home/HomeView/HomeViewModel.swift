//
//  HomeViewModel.swift
//  Features

import Foundation
import MovieListService

@MainActor
@Observable
public final class HomeViewModel {

    /// The first page fetched for each category (kept whole so we know `totalPages`
    /// and can seed the "Ver todos" screen without re-fetching).
    private var pages: [MovieCategory: MovieListResponse] = [:]
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let movieListService: MovieListService
    private let imageBaseURL: String

    public init(movieListService: MovieListService, imageBaseURL: String) {
        self.movieListService = movieListService
        self.imageBaseURL = imageBaseURL
    }

    // MARK: - Per-category accessors (used by the carousels)

    public var popular: [Movie] { movies(for: .popular) }
    public var topRated: [Movie] { movies(for: .topRated) }
    public var nowPlaying: [Movie] { movies(for: .nowPlaying) }
    public var upcoming: [Movie] { movies(for: .upcoming) }

    func movies(for category: MovieCategory) -> [Movie] { pages[category]?.results ?? [] }

    func firstPage(for category: MovieCategory) -> MovieListResponse? { pages[category] }

    /// Whether the category has more than the first page — drives the "Ver todos" button.
    func hasMorePages(for category: MovieCategory) -> Bool {
        (pages[category]?.totalPages ?? 0) > 1
    }

    // MARK: - Loading

    /// Loads every carousel's first page in parallel. Safe to call from `.task`:
    /// it no-ops while a load is already running.
    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let popular: Void = loadCategory(.popular)
        async let topRated: Void = loadCategory(.topRated)
        async let nowPlaying: Void = loadCategory(.nowPlaying)
        async let upcoming: Void = loadCategory(.upcoming)
        _ = await (popular, topRated, nowPlaying, upcoming)
    }

    private func loadCategory(_ category: MovieCategory) async {
        do { pages[category] = try await fetch(category, page: 1) }
        catch { errorMessage = error.localizedDescription }
    }

    /// Maps a category to its TMDB request (the per-category methods on the service).
    private func fetch(_ category: MovieCategory, page: Int) async throws -> MovieListResponse {
        switch category {
        case .popular: try await movieListService.popularMovies(page: page)
        case .topRated: try await movieListService.topRatedMovies(page: page)
        case .nowPlaying: try await movieListService.nowPlayingMovies(page: page)
        case .upcoming: try await movieListService.upcomingMovies(page: page)
        }
    }

    // MARK: - Navigation

    /// Builds the paginated full-list view model for a category, seeded with the
    /// already-loaded first page so it shows instantly.
    func makeAllMoviesViewModel(for category: MovieCategory) -> AllMoviesViewModel {
        AllMoviesViewModel(
            category: category,
            firstPage: pages[category],
            imageBaseURL: imageBaseURL,
            movieListService: movieListService
        )
    }

    // MARK: - Images

    /// Builds the poster URL for a movie: `<imageBaseURL>/<size><posterPath>`.
    /// Returns `nil` when the movie has no artwork or no base is configured.
    public func posterURL(for movie: Movie, size: String = "w500") -> URL? {
        Self.posterURL(for: movie, imageBaseURL: imageBaseURL, size: size)
    }

    static func posterURL(for movie: Movie, imageBaseURL: String, size: String) -> URL? {
        guard let posterPath = movie.posterPath, !imageBaseURL.isEmpty else { return nil }
        return URL(string: imageBaseURL + "/" + size + posterPath)
    }
}
