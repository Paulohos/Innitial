import AppConfiguration
import Foundation
import LocalStoreService
import Testing

@testable import NetworkLayer

@Suite("NetworkService")
struct NetworkServiceTests {

    // MARK: - Helpers

    /// Thread-safe capture of the `URLRequest` the service actually sent.
    /// (`testMock`'s provider is `@Sendable`, so we can't write to a plain `var`.)
    private final class RequestSpy: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: URLRequest?
        var request: URLRequest? { lock.lock(); defer { lock.unlock() }; return stored }
        func capture(_ request: URLRequest) { lock.lock(); defer { lock.unlock() }; stored = request }
    }

    /// Serves a scripted list of responses, one per request, sticking on the last
    /// once exhausted. Lets us model multi-request flows (e.g. 401 then 200).
    private final class ResponseSequence: @unchecked Sendable {
        private let lock = NSLock()
        private let responses: [NetworkResponse]
        private var index = 0
        private var calls = 0

        init(_ responses: [NetworkResponse]) { self.responses = responses }

        /// How many times a response has been requested so far.
        var callCount: Int { lock.lock(); defer { lock.unlock() }; return calls }

        func next() -> NetworkResponse {
            lock.lock(); defer { lock.unlock() }
            calls += 1
            let response = responses[min(index, responses.count - 1)]
            index += 1
            return response
        }
    }

    private func makeSUT(
        configuration: EnvironmentConfigurationService = .mock(
            baseUrl: "https://api.test",
            accessToken: "abc123",
            releaseVersionNumber: "1.0",
            systemVersion: "17.0",
            timeZoneIdentifier: "America/Sao_Paulo"
        ),
        store: LocalStoreService,
        retryOn401: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void = { completion in
            completion(.failure(NetworkServiceError.authenticationFailure))
        },
        response: @escaping @Sendable () -> NetworkResponse
    ) -> (sut: NetworkService, spy: RequestSpy) {
        let spy = RequestSpy()
        let sut = NetworkService.testMock(
            appConfiguration: configuration,
            localStore: store,
            retryOn401: retryOn401,
            mockValueProvider: { request in
                spy.capture(request)
                return response()
            }
        )
        return (sut, spy)
    }

    private func storeWithToken(_ token: String = "abc123") throws -> LocalStoreService {
        let store = LocalStoreService.inMemory()
        try store.save(token, for: \.authToken)
        return store
    }

    // MARK: - Headers

    @Test
    func `every request carries the standard headers and the bearer token`() async throws {
        let store = try storeWithToken("abc123")
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))

        let headers = try #require(spy.request?.allHTTPHeaderFields)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Accept"] == "application/json")
        #expect(headers["device"] == "ios")
        #expect(headers["version"] == "1.0")
        #expect(headers["osversion"] == "17.0")
        #expect(headers["tenant"] == "innitial")
        #expect(headers["requestedAt"] != nil)
        #expect(headers["timeZoneIdentifier"] == "America/Sao_Paulo")
        #expect(headers["source"] == "innitial")
        #expect(headers["Authorization"] == "Bearer abc123")
    }

    @Test
    func `the requestedAt header is an ISO 8601 UTC timestamp`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))

        let requestedAt = try #require(spy.request?.allHTTPHeaderFields?["requestedAt"])
        // e.g. "2023-07-21T17:19:29.744Z"
        let pattern = #/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/#
        #expect(requestedAt.wholeMatch(of: pattern) != nil, "Unexpected format: \(requestedAt)")
    }

    @Test
    func `a missing auth token fails the request with the default error`() async throws {
        // No access token configured → getHeaders masks it into the default error.
        let configuration = EnvironmentConfigurationService.mock(baseUrl: "https://api.test")
        let store = LocalStoreService.inMemory()
        let (sut, _) = makeSUT(configuration: configuration, store: store) { .mock(data: emptyMock, status: 200) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.defaultError(error) {
            // A missing token is masked into the generic default error by getHeaders.
            #expect(error.title == "Oops... Algo deu errado")
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Success

    @Test
    func `a 200 with a valid body decodes into the requested type`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: dummyMock, status: 200) }

        let result: Dummy = try await sut.call(endpoint: .popularMovies(page: 1))

        #expect(result == Dummy(dummy: "dummy"))
    }

    // MARK: - Error handling

    @Test
    func `a 400 with a well formed error body surfaces the servers default error`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: defaultErrorMock, status: 400) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.defaultError(error) {
            #expect(error.code == 123) // server's business code is preserved, not the HTTP status
            #expect(error.title == "Server title")
            #expect(error.message == "Server message")
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 400 with an unparseable error body falls back to the default error`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: emptyMock, status: 400) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.defaultError(error) {
            #expect(error.code == 400)
            #expect(error.title == "Oops... Algo deu errado")
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 400 without default error passes the raw status and data through`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: dummyMock, status: 400) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1), shouldReturnDefaultError: false)
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.unhandledHTTPStatus(status, data) {
            #expect(status == 400)
            #expect(data == dummyMock)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 500 with default error maps to the default error`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: defaultErrorMock, status: 500) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.defaultError(error) {
            #expect(error.code == 500)
            #expect(error.title == "Oops... Algo deu errado")
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 500 without default error surfaces a server error`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: defaultErrorMock, status: 500) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1), shouldReturnDefaultError: false)
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.serverError(status) {
            #expect(status == 500)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 200 that does not decode without default error throws a parsing failure`() async throws {
        let store = try storeWithToken()
        // emptyMock ({}) can't decode into Dummy (missing 'dummy')
        let (sut, _) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        do {
            let _: Dummy = try await sut.call(endpoint: .popularMovies(page: 1), shouldReturnDefaultError: false)
            Issue.record("Expected the call to throw")
        } catch NetworkServiceError.jsonParsingFailure {
            // ✅ expected
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - 401 auto-retry

    @Test
    func `a 401 triggers the automatic retry which fails by default`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(status: 401) }

        do {
            let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))
            Issue.record("Expected the call to throw")
        } catch NetworkServiceError.retryOn401 {
            // ✅ default retry closure reports failure
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test
    func `a 401 whose retry succeeds re-runs the request and returns the value`() async throws {
        let store = try storeWithToken()
        // First attempt is rejected with 401; after the retry handler succeeds the
        // request is replayed and the second response (200) is what we get back.
        let responses = ResponseSequence([
            .mock(status: 401),
            .mock(data: dummyMock, status: 200)
        ])
        // The refresh handler is injected at construction (it just succeeds here).
        let (sut, _) = makeSUT(
            store: store,
            retryOn401: { completion in completion(.success(())) }
        ) { responses.next() }

        let result: Dummy = try await sut.call(endpoint: .popularMovies(page: 1))

        #expect(result == Dummy(dummy: "dummy"))
        #expect(responses.callCount == 2) // original attempt + replay
    }

    // MARK: - URL building

    @Test
    func `popularMovies hits the popular path with the page query`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))

        let url = try #require(spy.request?.url)
        #expect(url.path.hasSuffix("/movie/popular"))
        #expect(url.query?.contains("page=1") == true)
    }

    @Test
    func `topRatedMovies hits the top rated path with the page query`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .topRatedMovies(page: 2))

        let url = try #require(spy.request?.url)
        #expect(url.path.hasSuffix("/movie/top_rated"))
        #expect(url.query?.contains("page=2") == true)
    }

    @Test
    func `upcomingMovies hits the upcoming path with the page query`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .upcomingMovies(page: 3))

        let url = try #require(spy.request?.url)
        #expect(url.path.hasSuffix("/movie/upcoming"))
        #expect(url.query?.contains("page=3") == true)
    }

    @Test
    func `nowPlayingMovies hits the now playing path with the page query`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .nowPlayingMovies(page: 1))

        let url = try #require(spy.request?.url)
        #expect(url.path.hasSuffix("/movie/now_playing"))
        #expect(url.query?.contains("page=1") == true)
    }

    @Test
    func `movieDetails hits the movie detail path with the language query`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .movieDetails(id: 42))

        let url = try #require(spy.request?.url)
        #expect(url.path.hasSuffix("/movie/42"))
        #expect(url.query?.contains("language=en-US") == true)
    }

    // MARK: - Body

    @Test
    func `a request body is JSON encoded and attached to the request`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1), body: Dummy(dummy: "hello"))

        let body = try #require(spy.request?.httpBody)
        let decoded = try JSONDecoder().decode(Dummy.self, from: body)
        #expect(decoded == Dummy(dummy: "hello"))
    }

    @Test
    func `a request without a body sends no http body`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(endpoint: .popularMovies(page: 1))

        #expect(spy.request?.httpBody == nil)
    }

    // MARK: - Discardable overload

    @Test
    func `the discardable call overload sends the request without returning a value`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        try await sut.call(endpoint: .popularMovies(page: 1))

        #expect(spy.request != nil)
    }

    // MARK: - Additional settings

    @Test
    func `appendHeader adds extra headers on top of the standard ones`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .popularMovies(page: 1),
            additionalSettings: [.appendHeader([["test": "test1"], ["test2": "test3"]])]
        )

        let headers = try #require(spy.request?.allHTTPHeaderFields)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"] == "Bearer abc123")
        #expect(headers["test"] == "test1")
        #expect(headers["test2"] == "test3")
    }

    @Test
    func `appendHeader can override a standard header without duplicating it`() async throws {
        let store = try storeWithToken("abc123")
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .popularMovies(page: 1),
            additionalSettings: [.appendHeader([["Authorization": "Bearer overridden"]])]
        )

        // setValue (not addValue) means the value is replaced, not comma-appended.
        let headers = try #require(spy.request?.allHTTPHeaderFields)
        #expect(headers["Authorization"] == "Bearer overridden")
    }

    @Test
    func `overrideHeader replaces every standard header with only the given ones`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .popularMovies(page: 1),
            additionalSettings: [.overrideHeader([["test": "test1"], ["test2": "test3"]])]
        )

        let headers = try #require(spy.request?.allHTTPHeaderFields)
        #expect(headers["Content-Type"] == nil)
        #expect(headers["device"] == nil)
        #expect(headers["Authorization"] == nil)
        #expect(headers["test"] == "test1")
        #expect(headers["test2"] == "test3")
    }

    @Test
    func `setTimeOut changes the requests timeout interval`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .popularMovies(page: 1),
            additionalSettings: [.setTimeOut(100)]
        )

        #expect(spy.request?.timeoutInterval == 100)
    }
}
