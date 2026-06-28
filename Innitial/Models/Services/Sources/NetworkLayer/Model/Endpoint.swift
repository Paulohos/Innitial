import Foundation

public enum Endpoint: Equatable {

    case listOfMovies
    case movieDetails(id: Int)
    case popularMovies(page: Int)
}

extension Endpoint {
    var path: String {
        switch self {
        case .listOfMovies:
            return "/movie/popular"
        case .movieDetails(let id):
            return "/movies/\(id)"
        case .popularMovies:
            return "/movie/popular"
        }
    }

    var queryItems: [APIQueryItem] {
        switch self {
        // `movieDetails` carries its id in the path (`/movies/{id}`), so no query item is needed.
        case .listOfMovies, .movieDetails:
            return []
        case .popularMovies(let page):
            return [.keyValue(key: "language", value: "en-US"), .keyValue(key: "page", value: String(page))]
        }
    }

    var requiresAccessToken: Bool {
        switch self {
        case .listOfMovies, .movieDetails, .popularMovies:
            return true
        }
    }


}

enum APIQueryItem {
    case keyValue(key: String, value: String)
//        case date(date: Date)
}
