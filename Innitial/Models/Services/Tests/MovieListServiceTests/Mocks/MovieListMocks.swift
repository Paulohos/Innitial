import Foundation

/// A full popular-style page: a first, fully-populated movie plus a second one with
/// no artwork (poster/backdrop `null`). Used to verify decoding end to end.
let popularPageMock = Data("""
{
  "page": 2,
  "results": [
    { "adult": false, "backdrop_path": "/back.jpg", "genre_ids": [28, 12],
      "id": 1011985, "original_language": "en", "original_title": "Kung Fu Panda 4",
      "overview": "Po is back.", "popularity": 1234.5, "poster_path": "/poster.jpg",
      "release_date": "2024-03-02", "title": "Kung Fu Panda 4", "video": false,
      "vote_average": 6.9, "vote_count": 100 },
    { "adult": false, "backdrop_path": null, "genre_ids": [],
      "id": 42, "original_language": "fr", "original_title": "Sans Affiche",
      "overview": "", "popularity": 0, "poster_path": null,
      "release_date": "", "title": "No Poster", "video": false,
      "vote_average": 0, "vote_count": 0 }
  ],
  "total_pages": 42,
  "total_results": 840
}
""".utf8)

/// A now-playing / upcoming page: carries the `dates` window that popular omits.
let nowPlayingPageMock = Data("""
{ "dates": { "maximum": "2024-04-10", "minimum": "2024-02-28" },
  "page": 1, "results": [], "total_pages": 5, "total_results": 90 }
""".utf8)
