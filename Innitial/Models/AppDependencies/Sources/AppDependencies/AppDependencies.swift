import AppConfiguration
import LocalStoreService
import NetworkLayer

/// The app's dependency container: holds one shared instance of each service.
///
/// Build it once at the app's composition root (`AppDependencies.live()`) and
/// inject it into the modules. Each module reads only the services it needs.
public struct AppDependencies: Sendable {
    public var configuration: EnvironmentConfigurationService
    public var localStore: LocalStoreService
    public var network: NetworkService
    // Add more services here as they appear, e.g.:
    // public var analytics: AnalyticsService

    public init(
        configuration: EnvironmentConfigurationService,
        localStore: LocalStoreService,
        network: NetworkService
    ) {
        self.configuration = configuration
        self.localStore = localStore
        self.network = network
    }
}

extension AppDependencies {
    /// Production container: real Info.plist config + UserDefaults/Keychain storage
    /// + a network service wired with both.
    public static func live() -> Self {
        let configuration = EnvironmentConfigurationService.live(bundle: .main)
        let localStore = LocalStoreService.live(keychainService: configuration.bundleID())
        return .init(
            configuration: configuration,
            localStore: localStore,
            network: NetworkService.live(appConfiguration: configuration, localStorageService: localStore)
        )
    }

    /// Container for tests / SwiftUI previews: mock config + in-memory storage.
    public static func mock() -> Self {
        let configuration = EnvironmentConfigurationService.mock(bundleID: "com.innitial.preview")
        let localStore = LocalStoreService.inMemory()
        return .init(
            configuration: configuration,
            localStore: localStore,
            network: NetworkService.mock(appConfiguration: configuration, localStorageService: localStore)
        )
    }
}
