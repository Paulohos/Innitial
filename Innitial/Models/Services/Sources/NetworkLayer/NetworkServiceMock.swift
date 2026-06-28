import AppConfiguration
import LocalStoreService
import Foundation

public typealias NetworkResponse = Result<(Data, HTTPURLResponse), Error>

extension NetworkService {
    /// Mock constructor for `NetworkService`.
    ///
    /// `mockValueProvider` is called for every request and decides what the service
    /// responds with. The handful of `NetworkResponse.mock(...)` helpers build the
    /// `(Data, HTTPURLResponse)` pair for you.
    ///
    /// Single canned response (Swift Testing):
    /// ```swift
    /// @Test func decodesBody() async throws {
    ///     let sut = NetworkService.mock(
    ///         appConfiguration: .mock(),
    ///         localStore: .inMemory(),
    ///         mockValueProvider: { .mock(data: dummyMock, status: 200) }
    ///     )
    ///     let result: Dummy = try await sut.call(endpoint: .listOfMovies)
    ///     #expect(result == Dummy(dummy: "dummy"))
    /// }
    /// ```
    ///
    /// A queue of responses, one popped per call (handy for multi-request flows):
    /// ```swift
    /// let queue = ResponseQueue([.mock(status: 401), .mock(data: dummyMock, status: 200)])
    /// let sut = NetworkService.mock(
    ///     appConfiguration: .mock(),
    ///     localStore: .inMemory(),
    ///     mockValueProvider: { queue.next() }
    /// )
    /// ```
    ///
    /// To also assert on the `URLRequest` that was sent, use `testMock`, whose provider
    /// receives the request before returning a response.
    ///
    /// - Parameters:
    ///   - appConfiguration: AppConfiguration dependency
    ///   - localStore: LocalStoreService dependency
    ///   - mockValueProvider: Supplies the response the service returns for each request.
    ///     Defaults to an empty `200`.
    /// - Returns: A NetworkService mock object
    public static func mock(
        appConfiguration: EnvironmentConfigurationService,
        localStore: LocalStoreService,
        retryOn401: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void = { completion in
            completion(.failure(NetworkServiceError.authenticationFailure))
        },
        mockValueProvider: @escaping @Sendable () -> NetworkResponse = {
            .success((Data(), HTTPURLResponse(
                url: URL(string: "https://mock.local")!,
                statusCode: 200, httpVersion: nil, headerFields: nil)!))
        }
    ) -> NetworkService {
        .init(
            appConfiguration: appConfiguration,
            localStore: localStore,
            retryOn401: retryOn401,
            baseNetworkRequest: { _ in
                switch mockValueProvider() {
                case .success(let value): return value
                case .failure(let error): throw error
                }
            }
        )
    }
}
