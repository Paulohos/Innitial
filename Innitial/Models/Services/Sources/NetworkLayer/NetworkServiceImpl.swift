import AppConfiguration
import Foundation
import LocalStorageService

extension NetworkService {
    /// "Live" constructor for NetworkService
    ///
    /// The service was devised to be super-minimal. Note that the *only* part that cannot be tested is the `baseNetworkRequest`
    /// function, upon which all the outer layers of the `public` interface are built upon. The `baseNetworkRequest` function's
    /// impl is the same signature as the `async` `URLSession` method.
    ///
    /// - Parameters:
    ///   - appConfiguration: AppConfiguration dependency
    ///   - localStorageService: LocalStorageService dependency
    ///   - retryOn401: Optional 401 refresh handler. Defaults to one that fails, so 401s
    ///     are treated as hard authentication failures unless the composition root injects one.
    /// - Returns: A live `NetworkService`
    public static func live(
        appConfiguration: EnvironmentConfigurationService,
        localStorageService: LocalStorageService,
        retryOn401: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void = { completion in
            completion(.failure(NetworkServiceError.authenticationFailure))
        }
    ) -> NetworkService {
        .init(
            appConfiguration: appConfiguration,
            localStorageService: localStorageService,
            retryOn401: retryOn401,
            baseNetworkRequest: {
                return try await URLSession.shared.data(for: $0)
            }
        )
    }

    /// This is for testing the live network service; it gives us an opportunity to capture the `URLRequest` that's sent so we can test on it
    static func testMock(
        appConfiguration: EnvironmentConfigurationService,
        localStorageService: LocalStorageService,
        retryOn401: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void = { completion in
            completion(.failure(NetworkServiceError.authenticationFailure))
        },
        mockValueProvider: @escaping @Sendable (URLRequest) -> NetworkResponse
    ) -> NetworkService {
        .init(
            appConfiguration: appConfiguration,
            localStorageService: localStorageService,
            retryOn401: retryOn401,
            baseNetworkRequest: { request in
                switch mockValueProvider(request) {
                case .success(let value): return value
                case .failure(let error): throw error
                }
            }
        )
    }
}
