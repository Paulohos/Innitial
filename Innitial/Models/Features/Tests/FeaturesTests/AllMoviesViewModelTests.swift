import Foundation
import Testing
import MovieListService
import Movies
@testable import Home

// Free builders (no `self` capture) so they can be used inside `@Sendable` mock closures.

private func sampleMovie(id: Int) -> Movie {
    Movie(
        id: id, title: "M\(id)", originalTitle: "M\(id)", originalLanguage: "en",
        overview: "", posterPath: nil, backdropPath: nil, releaseDate: "", genreIDs: [],
        popularity: 0, voteAverage: 0, voteCount: 0, adult: false, video: false
    )
}

/// A page with 20 movies whose ids encode the page number, so appended pages are distinguishable.
private func samplePage(_ page: Int, totalPages: Int, count: Int = 20) -> MovieListResponse {
    MovieListResponse(
        page: page,
        results: (0..<count).map { sampleMovie(id: page * 100 + $0) },
        totalPages: totalPages,
        totalResults: totalPages * count
    )
}

@MainActor
@Suite struct AllMoviesViewModelTests {

    private func makeSUT(
        firstPage: MovieListResponse,
        service: MovieListService
    ) -> AllMoviesViewModel {
        AllMoviesViewModel(
            category: .popular,
            firstPage: firstPage,
            imageBaseURL: "",
            movieListService: service,
            moviesService: .mock(detail: .sample)
        )
    }

    @Test func `is seeded with the first page`() {
        let sut = makeSUT(
            firstPage: samplePage(1, totalPages: 3),
            service: .paging { samplePage($0, totalPages: 3) }
        )

        #expect(sut.title == "Mais populares")
        #expect(sut.movies.count == 20)
        #expect(sut.hasMorePages == true)
    }

    @Test func `loadNextPage appends the next page and advances`() async {
        let sut = makeSUT(
            firstPage: samplePage(1, totalPages: 3),
            service: .paging { samplePage($0, totalPages: 3) }
        )

        await sut.loadNextPage()

        #expect(sut.movies.count == 40)
        #expect(sut.movies.last?.id == 2 * 100 + 19)
        #expect(sut.hasMorePages == true) // page 2 of 3
        #expect(sut.isLoadingNextPage == false)
    }

    @Test func `does not load past the last page`() async {
        let sut = makeSUT(
            firstPage: samplePage(1, totalPages: 1),
            service: .paging { samplePage($0, totalPages: 1) }
        )

        #expect(sut.hasMorePages == false)
        await sut.loadNextPage()

        #expect(sut.movies.count == 20) // unchanged
    }

    @Test func `loadNextPageIfNeeded loads only when near the end`() async {
        let sut = makeSUT(
            firstPage: samplePage(1, totalPages: 3),
            service: .paging { samplePage($0, totalPages: 3) }
        )

        // An early item must not trigger a fetch.
        await sut.loadNextPageIfNeeded(currentItem: sut.movies[0])
        #expect(sut.movies.count == 20)

        // An item within the prefetch distance (10) of the end triggers it.
        await sut.loadNextPageIfNeeded(currentItem: sut.movies[15])
        #expect(sut.movies.count == 40)
    }

    @Test func `with no seed it starts empty and shows an error`() {
        let sut = AllMoviesViewModel(
            category: .popular,
            firstPage: nil,
            imageBaseURL: "",
            movieListService: .failing(),
            moviesService: .mock(detail: .sample)
        )

        #expect(sut.movies.isEmpty)
        #expect(sut.errorMessage != nil)
        #expect(sut.hasMorePages == false)
    }

    @Test func `loadNextPage surfaces an error and keeps the current items`() async {
        let sut = makeSUT(
            firstPage: samplePage(1, totalPages: 3),
            service: .failing()
        )

        await sut.loadNextPage()

        #expect(sut.errorMessage != nil)
        #expect(sut.movies.count == 20)
        #expect(sut.isLoadingNextPage == false)
    }
}
