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

    private func makeSUT(
        configuration: EnvironmentConfigurationService = .mock(
            baseUrl: "https://api.test",
            releaseVersionNumber: "1.0",
            systemVersion: "17.0",
            timeZoneIdentifier: "America/Sao_Paulo"
        ),
        store: LocalStoreService,
        response: @escaping @Sendable () -> NetworkResponse
    ) -> (sut: NetworkService, spy: RequestSpy) {
        let spy = RequestSpy()
        let sut = NetworkService.testMock(
            appConfiguration: configuration,
            localStorageService: store,
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

        let _: NoReply = try await sut.call(endpoint: .listOfMovies)

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
    func `a missing auth token fails the request with noAuthTokenInStorage`() async throws {
        let store = LocalStoreService.inMemory() // no token saved
        let (sut, _) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        do {
            let _: NoReply = try await sut.call(endpoint: .listOfMovies)
            Issue.record("Expected the call to throw")
        } catch NetworkServiceError.noAuthTokenInStorage {
            // ✅ expected
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Success

    @Test
    func `a 200 with a valid body decodes into the requested type`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: dummyMock, status: 200) }

        let result: Dummy = try await sut.call(endpoint: .listOfMovies)

        #expect(result == Dummy(dummy: "dummy"))
    }

    // MARK: - Error handling

    @Test
    func `a 400 with a well formed error body surfaces the servers default error`() async throws {
        let store = try storeWithToken()
        let (sut, _) = makeSUT(store: store) { .mock(data: defaultErrorMock, status: 400) }

        do {
            let _: NoReply = try await sut.call(endpoint: .listOfMovies)
            Issue.record("Expected the call to throw")
        } catch let NetworkServiceError.defaultError(error) {
            #expect(error.code == 400)
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
            let _: NoReply = try await sut.call(endpoint: .listOfMovies)
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
            let _: NoReply = try await sut.call(endpoint: .listOfMovies, shouldReturnDefaultError: false)
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
            let _: NoReply = try await sut.call(endpoint: .listOfMovies)
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
            let _: NoReply = try await sut.call(endpoint: .listOfMovies, shouldReturnDefaultError: false)
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
            let _: Dummy = try await sut.call(endpoint: .listOfMovies, shouldReturnDefaultError: false)
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
            let _: NoReply = try await sut.call(endpoint: .listOfMovies)
            Issue.record("Expected the call to throw")
        } catch NetworkServiceError.retryOn401 {
            // ✅ default retry closure reports failure
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Additional settings

    @Test
    func `appendHeader adds extra headers on top of the standard ones`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .listOfMovies,
            additionalSettings: [.appendHeader([["test": "test1"], ["test2": "test3"]])]
        )

        let headers = try #require(spy.request?.allHTTPHeaderFields)
        #expect(headers["Content-Type"] == "application/json")
        #expect(headers["Authorization"] == "Bearer abc123")
        #expect(headers["test"] == "test1")
        #expect(headers["test2"] == "test3")
    }

    @Test
    func `overrideHeader replaces every standard header with only the given ones`() async throws {
        let store = try storeWithToken()
        let (sut, spy) = makeSUT(store: store) { .mock(data: emptyMock, status: 200) }

        let _: NoReply = try await sut.call(
            endpoint: .listOfMovies,
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
            endpoint: .listOfMovies,
            additionalSettings: [.setTimeOut(100)]
        )

        #expect(spy.request?.timeoutInterval == 100)
    }
}
