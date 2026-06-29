import Foundation
import Testing
import MovieListService
@testable import Home

@MainActor
@Suite struct HomeViewModelTests {

    @Test func `load populates every carousel on success`() async {
        let sut = HomeViewModel(
            movieListService: .mock(
                popularMovies: .sample,
                topRatedMovies: .sample,
                upcomingMovies: .sample,
                nowPlayingMovies: .sample
            ),
            imageBaseURL: "https://image.tmdb.org/t/p"
        )
        #expect(sut.popular.isEmpty)

        await sut.load()

        #expect(sut.popular.count == Movie.samples.count)
        #expect(sut.topRated.count == Movie.samples.count)
        #expect(sut.upcoming.count == Movie.samples.count)
        #expect(sut.nowPlaying.count == Movie.samples.count)
        #expect(sut.popular.first?.id == Movie.samples.first?.id)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test func `load sets an error message on failure`() async {
        let sut = HomeViewModel(movieListService: .failing(), imageBaseURL: "")

        await sut.load()

        #expect(sut.popular.isEmpty)
        #expect(sut.topRated.isEmpty)
        #expect(sut.upcoming.isEmpty)
        #expect(sut.nowPlaying.isEmpty)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test func `posterURL builds the TMDB image path`() {
        let sut = HomeViewModel(
            movieListService: .mock(),
            imageBaseURL: "https://image.tmdb.org/t/p"
        )
        let movie = Movie.samples[0]

        let url = sut.posterURL(for: movie, size: "w500")

        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w500\(movie.posterPath ?? "")")
    }

    @Test func `posterURL is nil without a base or a poster path`() {
        let noBase = HomeViewModel(movieListService: .mock(), imageBaseURL: "")
        #expect(noBase.posterURL(for: Movie.samples[0]) == nil)

        let sut = HomeViewModel(
            movieListService: .mock(),
            imageBaseURL: "https://image.tmdb.org/t/p"
        )
        let noArtwork = Movie(
            id: 1, title: "X", originalTitle: "X", originalLanguage: "en", overview: "",
            posterPath: nil, backdropPath: nil, releaseDate: "", genreIDs: [],
            popularity: 0, voteAverage: 0, voteCount: 0, adult: false, video: false
        )
        #expect(sut.posterURL(for: noArtwork) == nil)
    }
}
