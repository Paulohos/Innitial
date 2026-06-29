import Foundation
import Testing
@testable import MovieListService

@Suite("MovieListResponse")
struct MovieListResponseTests {

    @Test func `decodes a TMDB popular movies page`() throws {
        let response = try JSONDecoder().decode(MovieListResponse.self, from: popularPageMock)

        #expect(response.page == 2)
        #expect(response.totalPages == 42)
        #expect(response.totalResults == 840)
        #expect(response.dates == nil) // popular has no date window
        #expect(response.results.count == 2)

        let first = try #require(response.results.first)
        #expect(first.id == 1011985)
        #expect(first.title == "Kung Fu Panda 4")
        #expect(first.originalTitle == "Kung Fu Panda 4")
        #expect(first.originalLanguage == "en")
        #expect(first.posterPath == "/poster.jpg")
        #expect(first.backdropPath == "/back.jpg")
        #expect(first.genreIDs == [28, 12])
        #expect(first.voteAverage == 6.9)
        #expect(first.voteCount == 100)
        #expect(first.releaseDate == "2024-03-02")
        #expect(first.adult == false)

        // Missing artwork decodes as nil (not an empty string).
        #expect(response.results[1].posterPath == nil)
        #expect(response.results[1].backdropPath == nil)
    }

    @Test func `decodes the date window on now playing / upcoming pages`() throws {
        // now_playing and upcoming carry a `dates` window that popular omits.
        let response = try JSONDecoder().decode(MovieListResponse.self, from: nowPlayingPageMock)

        #expect(response.dates?.maximum == "2024-04-10")
        #expect(response.dates?.minimum == "2024-02-28")
        #expect(response.results.isEmpty)
        #expect(response.totalPages == 5)
    }
}
