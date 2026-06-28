#if DEBUG
public extension Movie {
    /// Sample movies (real TMDB entries) for previews and tests.
    static let samples: [Movie] = [
        Movie(
            id: 713704,
            title: "Evil Dead Rise",
            originalTitle: "Evil Dead Rise",
            originalLanguage: "en",
            overview: "Two sisters find an ancient vinyl that gives birth to bloodthirsty demons that run amok in a Los Angeles apartment building.",
            posterPath: "/mIBCtPvKZQlxubxKMeViO2UrP3q.jpg",
            backdropPath: "/7bWxAsNPv9CXHOhZbJVlj2KxgfP.jpg",
            releaseDate: "2023-04-12",
            genreIDs: [27, 53],
            popularity: 1696.367,
            voteAverage: 7,
            voteCount: 207,
            adult: false,
            video: false
        ),
        Movie(
            id: 758323,
            title: "The Pope's Exorcist",
            originalTitle: "The Pope's Exorcist",
            originalLanguage: "en",
            overview: "Father Gabriele Amorth, Chief Exorcist of the Vatican, investigates a young boy's terrifying possession.",
            posterPath: "/9JBEPLTPSm0d1mbEcLxULjJq9Eh.jpg",
            backdropPath: "/5Y5pz0NX7SZS9036I733F7uNcwK.jpg",
            releaseDate: "2023-04-05",
            genreIDs: [27, 53],
            popularity: 1073.229,
            voteAverage: 6.5,
            voteCount: 143,
            adult: false,
            video: false
        ),
        Movie(
            id: 385687,
            title: "Fast X",
            originalTitle: "Fast X",
            originalLanguage: "en",
            overview: "Dom Toretto and his family confront the most lethal opponent they've ever faced.",
            posterPath: "/jwMMQR69Xz9AYtX4u2uYJgfAAev.jpg",
            backdropPath: "/fI5RsaM0NSU6TqztRhA2pal5ezv.jpg",
            releaseDate: "2023-05-17",
            genreIDs: [28, 80, 53],
            popularity: 524.606,
            voteAverage: 7.3,
            voteCount: 312,
            adult: false,
            video: false
        ),
        Movie(
            id: 447365,
            title: "Guardians of the Galaxy Volume 3",
            originalTitle: "Guardians of the Galaxy Volume 3",
            originalLanguage: "en",
            overview: "Peter Quill, still reeling from the loss of Gamora, must rally his team to defend the universe.",
            posterPath: "/r2J02Z2OpNTctfOSN1Ydgii51I3.jpg",
            backdropPath: "/7TUp4uKIaX9c2TAZLPwjty5A0EP.jpg",
            releaseDate: "2023-05-03",
            genreIDs: [878, 12, 28],
            popularity: 239.132,
            voteAverage: 8.1,
            voteCount: 980,
            adult: false,
            video: false
        )
    ]

    /// A single sample movie.
    static let sample = samples[0]
}

public extension MovieListResponse {
    /// A sample page of popular movies for previews and tests.
    static let sample = MovieListResponse(
        page: 1,
        results: Movie.samples,
        totalPages: 1,
        totalResults: 369
    )
}
#endif
