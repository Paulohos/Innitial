import Testing
import MovieListService
@testable import Home

@MainActor
@Suite struct HomeViewModelTests {

    // Placeholder smoke test: HomeViewModel has no behavior yet. Replace with real
    // expectations once it loads movies from MovieListService.
    @Test func buildsWithAMockService() {
        _ = HomeViewModel(movieListService: .mock(), imageBaseURL: "")
    }
}
