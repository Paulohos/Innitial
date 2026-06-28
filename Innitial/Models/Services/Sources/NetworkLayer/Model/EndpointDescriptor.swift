public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

// swiftlint:disable identifier_name
enum APIVersion: String {
    case v1 = "1"
    case v2 = "2"
    case v3 = "3"
    case v4 = "4"
}

enum APIOrigin {
    /// Localized  API. Almost always requires authentication in the form of `accessToken` or `refreshToken`
    /// this is the only API that uses these tokens.
    case localizedAPI
    /// The custom API. We use it when/if we access and external API .
    case custom(_ baseURL: String)
}

struct EndpointDescriptor {
    let origin: APIOrigin
    let version: APIVersion
    let method: HTTPMethod

    static func localizedAPI(
        version: APIVersion = .v3,
        method: HTTPMethod = .get
    ) -> Self {
        .init(origin: .localizedAPI, version: version, method: method)
    }

    static func customAPI(_ baseURL: String, method: HTTPMethod = .get) -> Self {
        .init(origin: .custom(baseURL), version: .v3, method: method)
    }
}

extension Endpoint {
    var descriptor: EndpointDescriptor {
        switch self {
        case .listOfMovies:
            return .localizedAPI()
        case .movieDetails:
            return .localizedAPI()
        case .popularMovies:
            return .localizedAPI()
        }
    }
}
