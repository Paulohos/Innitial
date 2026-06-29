import Foundation
import Testing
@testable import MoviesService

@Suite("MovieDetail")
struct MovieDetailTests {

    @Test func `decodes the TMDB movie detail payload`() throws {
        let detail = try JSONDecoder().decode(MovieDetail.self, from: sampleMovieDetailJSON)

        #expect(detail.id == 11)
        #expect(detail.title == "Star Wars")
        #expect(detail.originalTitle == "Star Wars")
        #expect(detail.runtime == 121)
        #expect(detail.status == "Released")
        #expect(detail.voteAverage == 8.2)
        #expect(detail.posterPath == "/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg")

        #expect(detail.genres.count == 3)
        #expect(detail.genres.first?.name == "Adventure")

        #expect(detail.productionCompanies.count == 2)
        #expect(detail.productionCompanies.first?.name == "Lucasfilm Ltd.")

        #expect(detail.spokenLanguages.first?.englishName == "English")
        #expect(detail.originCountry == ["US"])

        #expect(detail.belongsToCollection?.name == "Star Wars Collection")
    }

    @Test func `belongs_to_collection is optional`() throws {
        // The same payload without the collection key decodes with `belongsToCollection == nil`.
        let json = Data("""
        { "id": 1, "title": "X", "original_title": "X", "original_language": "en",
          "overview": "", "tagline": "", "status": "Released", "release_date": "2020-01-01",
          "budget": 0, "revenue": 0, "popularity": 0, "vote_average": 0, "vote_count": 0,
          "adult": false, "video": false, "genres": [], "production_companies": [],
          "production_countries": [], "spoken_languages": [], "origin_country": [] }
        """.utf8)

        let detail = try JSONDecoder().decode(MovieDetail.self, from: json)
        #expect(detail.belongsToCollection == nil)
        #expect(detail.runtime == nil)
    }
}
