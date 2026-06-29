import Foundation
import Testing
import AppConfiguration
import LocalStoreService
import NetworkLayer
@testable import MovieListService

@Suite("MovieListService")
struct MovieListServiceTests {

    /// Builds a `.live` service backed by a mocked network that always answers with
    /// `data`/`status`. The store carries an auth token so the request is allowed
    /// through (mirrors the NetworkLayer tests).
    private func liveSUT(status: Int = 200, data: Data = popularPageMock) throws -> MovieListService {
        let store = LocalStoreService.inMemory()
        try store.save("token", for: \.authToken)
        let network = NetworkService.mock(
            appConfiguration: .mock(baseUrl: "https://api.test", accessToken: "abc123"),
            localStore: store,
            mockValueProvider: { .mock(data: data, status: status) }
        )
        return .live(network)
    }

    /// Asserts the whole `MovieListResponse` (and its first `Movie`) decoded correctly.
    /// `sourceLocation` is forwarded so a failure points at the calling test.
    private func expectFullyDecoded(
        _ response: MovieListResponse,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        #expect(response.page == 2, sourceLocation: sourceLocation)
        #expect(response.totalPages == 42, sourceLocation: sourceLocation)
        #expect(response.totalResults == 840, sourceLocation: sourceLocation)
        #expect(response.dates == nil, sourceLocation: sourceLocation) // popular has no date window
        #expect(response.results.count == 2, sourceLocation: sourceLocation)

        let movie = try #require(response.results.first, sourceLocation: sourceLocation)
        #expect(movie.id == 1011985, sourceLocation: sourceLocation)
        #expect(movie.title == "Kung Fu Panda 4", sourceLocation: sourceLocation)
        #expect(movie.originalTitle == "Kung Fu Panda 4", sourceLocation: sourceLocation)
        #expect(movie.originalLanguage == "en", sourceLocation: sourceLocation)
        #expect(movie.overview == "Po is back.", sourceLocation: sourceLocation)
        #expect(movie.posterPath == "/poster.jpg", sourceLocation: sourceLocation)
        #expect(movie.backdropPath == "/back.jpg", sourceLocation: sourceLocation)
        #expect(movie.genreIDs == [28, 12], sourceLocation: sourceLocation)
        #expect(movie.popularity == 1234.5, sourceLocation: sourceLocation)
        #expect(movie.voteAverage == 6.9, sourceLocation: sourceLocation)
        #expect(movie.voteCount == 100, sourceLocation: sourceLocation)
        #expect(movie.releaseDate == "2024-03-02", sourceLocation: sourceLocation)
        #expect(movie.adult == false, sourceLocation: sourceLocation)
        #expect(movie.video == false, sourceLocation: sourceLocation)

        // Missing artwork decodes as nil (not an empty string).
        #expect(response.results[1].posterPath == nil, sourceLocation: sourceLocation)
        #expect(response.results[1].backdropPath == nil, sourceLocation: sourceLocation)
    }

    // MARK: - popularMovies

    @Test func `popularMovies succeeds and decodes the full page`() async throws {
        try expectFullyDecoded(try await liveSUT().popularMovies())
    }

    @Test func `popularMovies propagates a network failure`() async throws {
        let sut = try liveSUT(status: 500)
        await #expect(throws: (any Error).self) { _ = try await sut.popularMovies() }
    }

    // MARK: - topRatedMovies

    @Test func `topRatedMovies succeeds and decodes the full page`() async throws {
        try expectFullyDecoded(try await liveSUT().topRatedMovies())
    }

    @Test func `topRatedMovies propagates a network failure`() async throws {
        let sut = try liveSUT(status: 500)
        await #expect(throws: (any Error).self) { _ = try await sut.topRatedMovies() }
    }

    // MARK: - upcomingMovies

    @Test func `upcomingMovies succeeds and decodes the full page`() async throws {
        try expectFullyDecoded(try await liveSUT().upcomingMovies())
    }

    @Test func `upcomingMovies propagates a network failure`() async throws {
        let sut = try liveSUT(status: 500)
        await #expect(throws: (any Error).self) { _ = try await sut.upcomingMovies() }
    }

    // MARK: - nowPlayingMovies

    @Test func `nowPlayingMovies succeeds and decodes the full page`() async throws {
        try expectFullyDecoded(try await liveSUT().nowPlayingMovies())
    }

    @Test func `nowPlayingMovies propagates a network failure`() async throws {
        let sut = try liveSUT(status: 500)
        await #expect(throws: (any Error).self) { _ = try await sut.nowPlayingMovies() }
    }

    // MARK: - mock factory

    @Test func `mock returns the seeded page and empty for the others`() async throws {
        let popular = MovieListResponse(
            page: 1, results: Movie.samples, totalPages: 2, totalResults: 369
        )
        let sut = MovieListService.mock(popularMovies: popular)

        #expect(try await sut.popularMovies().results.count == Movie.samples.count)
        #expect(try await sut.topRatedMovies().results.isEmpty)
        #expect(try await sut.upcomingMovies().results.isEmpty)
        #expect(try await sut.nowPlayingMovies().results.isEmpty)
    }

    @Test func `mock seeds each category independently`() async throws {
        func page(_ value: Int) -> MovieListResponse {
            MovieListResponse(page: value, results: [], totalPages: value, totalResults: value)
        }
        let sut = MovieListService.mock(
            popularMovies: page(1),
            topRatedMovies: page(2),
            upcomingMovies: page(3),
            nowPlayingMovies: page(4)
        )

        #expect(try await sut.popularMovies().page == 1)
        #expect(try await sut.topRatedMovies().page == 2)
        #expect(try await sut.upcomingMovies().page == 3)
        #expect(try await sut.nowPlayingMovies().page == 4)
    }
}
