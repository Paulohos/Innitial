import Foundation

public enum Endpoint: Equatable {

    case movieDetails(id: Int)
    case popularMovies(page: Int)
    case topRatedMovies(page: Int)
    case upcomingMovies(page: Int)
    case nowPlayingMovies(page: Int)
}

extension Endpoint {
    var path: String {
        switch self {
        case .movieDetails(let id):
            return "/movies/\(id)"
        case .popularMovies:
            return "/movie/popular"
        case .topRatedMovies:
            return "/movie/top_rated"
        case .upcomingMovies:
            return "/movie/upcoming"
        case .nowPlayingMovies:
            return "/movie/now_playing"
        }
    }

    var queryItems: [APIQueryItem] {
        switch self {
        // `movieDetails` carries its id in the path (`/movies/{id}`), so no query item is needed.
        case .movieDetails:
            return []
        case let .popularMovies(page),
             let .topRatedMovies(page),
             let .upcomingMovies(page),
             let .nowPlayingMovies(page):
            return [.keyValue(key: "language", value: "en-US"), .keyValue(key: "page", value: String(page))]
        }
    }

    var requiresAccessToken: Bool {
        switch self {
        case .movieDetails, .popularMovies,
             .topRatedMovies, .upcomingMovies, .nowPlayingMovies:
            return true
        }
    }


}

enum APIQueryItem {
    case keyValue(key: String, value: String)
//        case date(date: Date)
}
