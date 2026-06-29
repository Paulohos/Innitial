//
//  MovieDetailViewModel.swift
//  Features

import Foundation
import AppConfiguration
import Dependencies
import MoviesService
import MovieListService

@MainActor
@Observable
final class MovieDetailViewModel {

    private(set) var detail: MovieDetail?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Not part of the detail endpoint — fetched later. Empty hides the section.
    private(set) var cast: [CastMember] = []
    private(set) var recommendations: [Movie] = []

    private let movieID: Int

    @ObservationIgnored @Dependency(\.moviesService) private var moviesService
    @ObservationIgnored @Dependency(\.configuration) private var configuration

    /// TMDB artwork base URL, taken straight from the configuration.
    private var imageBaseURL: String { configuration.bannerUrl() }

    init(movieID: Int) {
        self.movieID = movieID
    }

    func load() async {
        guard detail == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do { detail = try await moviesService.movieDetail(id: movieID) }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Display helpers

    /// Vote average (0–10) as a percentage, e.g. 8.2 → 82.
    var ratingPercent: Int { Int(((detail?.voteAverage ?? 0) * 10).rounded()) }

    var titleWithYear: String {
        guard let detail else { return "" }
        let year = detail.releaseDate.prefix(4)
        return year.isEmpty ? detail.title : "\(detail.title) (\(year))"
    }

    /// `yyyy-MM-dd` → `dd/MM/yyyy (BR)`.
    var releaseDateText: String {
        guard let date = detail?.releaseDate else { return "" }
        let parts = date.split(separator: "-")
        guard parts.count == 3 else { return date }
        return "\(parts[2])/\(parts[1])/\(parts[0]) (BR)"
    }

    /// Runtime in minutes → `1h 53m`. `nil` when unknown (hides it).
    var runtimeText: String? {
        guard let runtime = detail?.runtime, runtime > 0 else { return nil }
        return "\(runtime / 60)h \(runtime % 60)m"
    }

    func backdropURL() -> URL? { imageURL(detail?.backdropPath, size: "w780") }
    func castImageURL(_ member: CastMember) -> URL? { imageURL(member.profilePath, size: "w185") }
    func posterURL(for movie: Movie) -> URL? { imageURL(movie.posterPath, size: "w500") }

    private func imageURL(_ path: String?, size: String) -> URL? {
        guard let path, !imageBaseURL.isEmpty else { return nil }
        return URL(string: imageBaseURL + "/" + size + path)
    }
}

#if DEBUG
extension MovieDetailViewModel {
    /// A fully-seeded view model for SwiftUI previews (no network).
    static func preview(
        detail: MovieDetail = .sample,
        cast: [CastMember] = CastMember.mock,
        recommendations: [Movie] = Movie.samples,
        imageBaseURL: String = "https://image.tmdb.org/t/p"
    ) -> MovieDetailViewModel {
        let viewModel = withDependencies {
            $0.moviesService = .mock(detail: detail)
            $0.configuration = .mock(bannerUrl: imageBaseURL)
        } operation: {
            MovieDetailViewModel(movieID: detail.id)
        }
        viewModel.detail = detail
        viewModel.cast = cast
        viewModel.recommendations = recommendations
        return viewModel
    }
}
#endif
