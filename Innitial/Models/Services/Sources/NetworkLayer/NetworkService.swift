import AppConfiguration
import Foundation
import LocalStoreService
import os

/// Shared logger for the networking layer. Use this instead of `print` so output
/// is categorized, filterable in Console.app, and silenced in release builds.
let logger = Logger(subsystem: "com.innitial.network", category: "NetworkService")

public struct NetworkService: Sendable {

    /// Lets us access properties that we need to send to the server with every request
    let appConfiguration: EnvironmentConfigurationService
    /// Used to retrieve the `.endpoint` for API requests that need it
    let localStore: LocalStoreService
    /// Used for automatic 401 token refreshed; re-set by `LoginService` when it is constructed (hence why `class NetworkService`, because we
    /// need the value to propagate to all NetworkService objects underneath the Services.
    var retryOn401: @Sendable(@escaping (Result<Void, Error>) -> Void) -> Void

    /// This function is the "most minimal async network function"; it's the only piece that needs to depend
    /// on `URLSession`. All other functionality is built on top of this base. This is the only piece that is *not testable*.
    var baseNetworkRequest: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    /// Whether a custom 401 retry handler has been installed via `setRetryOn401(_:)`.
    /// While `false`, the default handler is used, which always reports failure.
    private(set) var hasRetryHandler: Bool = false

    public init(
        appConfiguration: EnvironmentConfigurationService,
        localStore: LocalStoreService,
        baseNetworkRequest: @Sendable @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.appConfiguration = appConfiguration
        self.localStore = localStore
        self.baseNetworkRequest = baseNetworkRequest
        self.retryOn401 = { completion in completion(.failure(NetworkServiceError.authenticationFailure)) }
    }

    public mutating func setRetryOn401(_ retryClosure: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        logger.debug("🌐 Automatic API call 401 retry closure set ✅")
        hasRetryHandler = true
        retryOn401 = retryClosure
    }
}
