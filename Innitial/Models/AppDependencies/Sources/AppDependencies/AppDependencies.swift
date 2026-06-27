import AppConfiguration
import LocalStoreService

/// The app's dependency container: holds one shared instance of each service.
///
/// Build it once at the app's composition root (`AppDependencies.live()`) and
/// inject it into the modules. Each module reads only the services it needs.
public struct AppDependencies: Sendable {
    public var configuration: EnvironmentConfigurationService
    public var localStore: LocalStoreService
    // Add more services here as they appear, e.g.:
    // public var network: NetworkService
    // public var analytics: AnalyticsService

    public init(
        configuration: EnvironmentConfigurationService,
        localStore: LocalStoreService
    ) {
        self.configuration = configuration
        self.localStore = localStore
    }
}

extension AppDependencies {
    /// Production container: real Info.plist config + UserDefaults/Keychain storage.
    /// The Keychain namespace reuses the app's bundle id from `AppConfiguration`.
    public static func live() -> Self {
        let configuration = EnvironmentConfigurationService.live(bundle: .main)
        return .init(
            configuration: configuration,
            localStore: .live(keychainService: configuration.bundleID())
        )
    }

    /// Container for tests / SwiftUI previews: mock config + in-memory storage.
    public static func mock() -> Self {
        .init(
            configuration: .mock(bundleID: "com.innitial.preview"),
            localStore: .inMemory()
        )
    }
}
