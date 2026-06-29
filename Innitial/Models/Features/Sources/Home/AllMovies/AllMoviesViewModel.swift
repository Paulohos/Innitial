//
//  AllMoviesViewModel.swift
//  Features

import Foundation
import MovieListService
import Movies

/// Drives the paginated "Ver todos" screen for a single category. It is self-contained:
/// it holds the service and the category and issues its own requests (no callback to Home).
/// Seeded with the first page already fetched on Home; loads further pages on demand
/// (infinite scroll) until `totalPages` is reached.
@MainActor
@Observable
final class AllMoviesViewModel {

    let category: MovieCategory
    private(set) var movies: [Movie]
    private(set) var isLoadingNextPage = false
    private(set) var errorMessage: String?

    private var page: Int
    private let totalPages: Int
    private let imageBaseURL: String
    private let movieListService: MovieListService
    private let moviesService: MoviesService

    /// How many items from the end should trigger the next-page fetch.
    private let prefetchDistance = 10

    init(
        category: MovieCategory,
        firstPage: MovieListResponse?,
        imageBaseURL: String,
        movieListService: MovieListService,
        moviesService: MoviesService
    ) {
        self.category = category
        self.movies = firstPage?.results ?? []
        self.page = firstPage?.page ?? 0
        self.totalPages = firstPage?.totalPages ?? 0
        self.imageBaseURL = imageBaseURL
        self.movieListService = movieListService
        self.moviesService = moviesService

        // No seed means the category never loaded — surface an error instead of an empty screen.
        if firstPage == nil {
            errorMessage = "Não foi possível carregar os filmes."
        }
    }

    var title: String { category.title }

    var hasMorePages: Bool { page < totalPages }

    /// Called as each cell appears. Fetches the next page once the visible item is
    /// within `prefetchDistance` of the end.
    func loadNextPageIfNeeded(currentItem: Movie) async {
        guard hasMorePages, !isLoadingNextPage else { return }
        guard let index = movies.firstIndex(where: { $0.id == currentItem.id }) else { return }
        guard index >= movies.count - prefetchDistance else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard hasMorePages, !isLoadingNextPage else { return }
        isLoadingNextPage = true
        errorMessage = nil
        defer { isLoadingNextPage = false }

        do {
            let next = try await fetch(page: page + 1)
            page = next.page
            movies.append(contentsOf: next.results)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Maps the category to its TMDB request — the screen owns its own fetching.
    private func fetch(page: Int) async throws -> MovieListResponse {
        switch category {
        case .popular: try await movieListService.popularMovies(page: page)
        case .topRated: try await movieListService.topRatedMovies(page: page)
        case .nowPlaying: try await movieListService.nowPlayingMovies(page: page)
        case .upcoming: try await movieListService.upcomingMovies(page: page)
        }
    }

    func posterURL(for movie: Movie, size: String = "w500") -> URL? {
        HomeViewModel.posterURL(for: movie, imageBaseURL: imageBaseURL, size: size)
    }

    /// Builds the detail view model for a tapped movie (presented as a modal).
    func makeMovieDetailViewModel(for movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(movieID: movie.id, moviesService: moviesService, imageBaseURL: imageBaseURL)
    }
}
