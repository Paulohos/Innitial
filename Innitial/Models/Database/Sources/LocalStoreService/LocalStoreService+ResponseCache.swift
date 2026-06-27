import Foundation

/// On-disk envelope for a cached API response: the raw server bytes plus when
/// they were stored, so reads can enforce a TTL (`maxAge`).
struct CachedResponse: Codable, Sendable {
    let data: Data
    let storedAt: Date
}

extension LocalStoreService {
    /// Caches the raw response bytes for `url` (offline support).
    ///
    /// The key is the request URL; the bytes are wrapped with a timestamp and
    /// written to the file-system backend.
    public func cacheResponse(_ data: Data, for url: URL, now: Date = Date()) throws {
        let envelope = CachedResponse(data: data, storedAt: now)
        let encoded = try JSONEncoder().encode(envelope)
        try fileSystem.saveData(encoded, url.absoluteString)
    }

    /// Returns the cached response bytes for `url`, or `nil` if absent or older
    /// than `maxAge`. Stale entries are deleted on read.
    public func cachedResponseData(
        for url: URL,
        maxAge: TimeInterval,
        now: Date = Date()
    ) throws -> Data? {
        guard let encoded = try fileSystem.loadData(url.absoluteString) else { return nil }
        let envelope = try JSONDecoder().decode(CachedResponse.self, from: encoded)

        guard now.timeIntervalSince(envelope.storedAt) <= maxAge else {
            try removeCachedResponse(for: url)   // stale → drop it
            return nil
        }
        return envelope.data
    }

    /// Decodes the cached response for `url` into `T`, honoring `maxAge`.
    public func cachedResponse<T: Decodable>(
        _ type: T.Type = T.self,
        for url: URL,
        maxAge: TimeInterval,
        now: Date = Date(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> T? {
        guard let data = try cachedResponseData(for: url, maxAge: maxAge, now: now) else { return nil }
        return try decoder.decode(T.self, from: data)
    }

    /// Removes any cached response for `url`.
    public func removeCachedResponse(for url: URL) throws {
        try fileSystem.removeValue(url.absoluteString)
    }
}
