import Foundation

public enum Endpoint: Equatable {

    case listOfMovies
    case movieDetails(id: Int)
}

extension Endpoint {
    var path: String {
        switch self {
        case .listOfMovies:
            return "/movie/popular"
        case .movieDetails(let id):
            return "/movies/\(id)"
        }
    }

    var queryItems: [APIQueryItem] {
        switch self {
        case .listOfMovies:
            return []
        case .movieDetails(let id):
            return [.keyValue(key: "id", value: String(id))]
        }
    }

    var requiresAccessToken: Bool {
        switch self {
        case .listOfMovies, .movieDetails:
            return true
        }
    }


}

enum APIQueryItem {
    case keyValue(key: String, value: String)
//        case date(date: Date)
}
