import Foundation
import Testing
@testable import Home

@MainActor
@Suite struct MovieDetailViewModelTests {

    @Test func `formats title, date, runtime and rating from the detail`() {
        // .preview() is seeded with the Star Wars sample (1977-05-25, 121 min, 8.2).
        let sut = MovieDetailViewModel.preview()

        #expect(sut.titleWithYear == "Star Wars (1977)")
        #expect(sut.releaseDateText == "25/05/1977 (BR)")
        #expect(sut.runtimeText == "2h 1m")
        #expect(sut.ratingPercent == 82)
    }
}
