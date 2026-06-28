import AppConfiguration
import Foundation
import LocalStoreService

public struct NetworkService: Sendable {

    /// Lets us access properties that we need to send to the server with every request
    let appConfiguration: EnvironmentConfigurationService
    /// Used to retrieve the `.endpoint` for API requests that need it
    let localStorageService: LocalStoreService
    /// Used for automatic 401 token refreshed; re-set by `LoginService` when it is constructed (hence why `class NetworkService`, because we
    /// need the value to propagate to all NetworkService objects underneath the Services.
    var retryOn401: @Sendable(@escaping (Result<Void, Error>) -> Void) -> Void

    /// This function is the "most minimal async network function"; it's the only piece that needs to depend
    /// on `URLSession`. All other functionality is built on top of this base. This is the only piece that is *not testable*.
    var baseNetworkRequest: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private(set) var setRetryOn401: Bool = false

    public init(
        appConfiguration: EnvironmentConfigurationService,
        localStorageService: LocalStoreService,
        baseNetworkRequest: @Sendable @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.appConfiguration = appConfiguration
        self.localStorageService = localStorageService
        self.baseNetworkRequest = baseNetworkRequest
        self.retryOn401 = { completion in completion(.failure(NetworkServiceError.authenticationFailure)) }
    }

    public mutating func setRetryOn401(_ retryClosure: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        // precondition(!setRetryOn401)

        print("🌐 Automatic API call 401 retry closure set ✅")
        setRetryOn401 = true
        retryOn401 = retryClosure
    }
}
