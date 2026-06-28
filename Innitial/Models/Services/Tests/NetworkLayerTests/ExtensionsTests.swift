import Foundation
import Testing

@testable import NetworkLayer

@Suite("Date.convertToUTC")
struct DateConvertToUTCTests {

    @Test
    func `the unix epoch renders as midnight UTC`() {
        // timeIntervalSince1970 == 0 is exactly 1970-01-01T00:00:00Z, so this also
        // proves the output is in UTC regardless of the device's time zone.
        let date = Date(timeIntervalSince1970: 0)
        #expect(date.convertToUTC() == "1970-01-01T00:00:00.000Z")
    }

    @Test
    func `milliseconds are included with three digits`() {
        let date = Date(timeIntervalSince1970: 0.5)
        #expect(date.convertToUTC() == "1970-01-01T00:00:00.500Z")
    }

    @Test
    func `a real timestamp is formatted as the server expects`() {
        // 1_609_459_200 == 2021-01-01T00:00:00Z
        let date = Date(timeIntervalSince1970: 1_609_459_200)
        #expect(date.convertToUTC() == "2021-01-01T00:00:00.000Z")
    }
}

@Suite("URL.addQueryItems")
struct URLAddQueryItemsTests {

    @Test
    func `appends a query to a url that has none`() throws {
        let url = URL(string: "https://api.test/movies")!

        let result = try #require(url.addQueryItems([URLQueryItem(name: "page", value: "2")]))

        #expect(result.absoluteString == "https://api.test/movies?page=2")
    }

    @Test
    func `replaces an existing query rather than merging it`() throws {
        let url = URL(string: "https://api.test/movies?page=1&stale=yes")!

        let result = try #require(url.addQueryItems([URLQueryItem(name: "page", value: "2")]))

        #expect(result.query == "page=2")
    }

    @Test
    func `preserves the order of multiple items`() throws {
        let url = URL(string: "https://api.test/search")!

        let result = try #require(url.addQueryItems([
            URLQueryItem(name: "q", value: "matrix"),
            URLQueryItem(name: "page", value: "2")
        ]))

        #expect(result.query == "q=matrix&page=2")
    }

    @Test
    func `percent-encodes special characters in values`() throws {
        let url = URL(string: "https://api.test/search")!

        let result = try #require(url.addQueryItems([URLQueryItem(name: "q", value: "star wars")]))

        #expect(result.absoluteString == "https://api.test/search?q=star%20wars")
    }
}
