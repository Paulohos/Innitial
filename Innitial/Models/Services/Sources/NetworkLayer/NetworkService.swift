import AppConfiguration
import Foundation
import LocalStoreService
import os

/// Shared logger for the networking layer. Use this instead of `print` so output
/// is categorized, filterable in Console.app, and silenced in release builds.
let logger = Logger(subsystem: "com.innitial.network", category: "NetworkService")

/// Shared JSON coders, reused across requests to avoid re-allocating them on every call.
let sharedJSONEncoder = JSONEncoder()
let sharedJSONDecoder = JSONDecoder()

public struct NetworkService: Sendable {

    /// Lets us access properties that we need to send to the server with every request
    let appConfiguration: EnvironmentConfigurationService
    /// Used to retrieve the `.endpoint` for API requests that need it
    let localStore: LocalStoreService
    /// Hook for refreshing credentials when a request comes back `401`. It is given a
    /// completion that it must call with `.success` (retry the original request) or
    /// `.failure` (give up). Provided at construction by the composition root; the
    /// default just fails, so a `NetworkService` built without a refresh handler treats
    /// every `401` as a hard authentication failure.
    let retryOn401: @Sendable (@escaping (Result<Void, Error>) -> Void) -> Void

    /// This function is the "most minimal async network function"; it's the only piece that needs to depend
    /// on `URLSession`. All other functionality is built on top of this base. This is the only piece that is *not testable*.
    let baseNetworkRequest: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public init(
        appConfiguration: EnvironmentConfigurationService,
        localStore: LocalStoreService,
        retryOn401: @Sendable @escaping (@escaping (Result<Void, Error>) -> Void) -> Void = { completion in
            completion(.failure(NetworkServiceError.authenticationFailure))
        },
        baseNetworkRequest: @Sendable @escaping (URLRequest) async throws -> (Data, URLResponse)) {
        self.appConfiguration = appConfiguration
        self.localStore = localStore
        self.retryOn401 = retryOn401
        self.baseNetworkRequest = baseNetworkRequest
    }
}
