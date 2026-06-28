import Foundation

extension URL {
    /// Returns a copy of the URL with its query replaced by `queryItems`,
    /// or `nil` if the URL can't be decomposed/recomposed — so the caller can
    /// treat that as a real failure instead of silently dropping the items.
    func addQueryItems(_ queryItems: [URLQueryItem]) -> URL? {
        guard var urlComponents = URLComponents(string: absoluteString) else { return nil }
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}
