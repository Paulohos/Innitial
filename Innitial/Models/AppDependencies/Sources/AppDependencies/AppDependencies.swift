import AppConfiguration
import LocalStoreService
import NetworkLayer
import MovieListService
import Movies

/// The app's dependency container: holds one shared instance of each service.
///
/// Build it once at the app's composition root (`AppDependencies.live()`) and
/// inject it into the modules. Each module reads only the services it needs.
public struct AppDependencies: Sendable {
    public var configuration: EnvironmentConfigurationService
    public var localStore: LocalStoreService
    public var network: NetworkService
    public var movieListService: MovieListService
    public var moviesService: MoviesService
    // Add more services here as they appear, e.g.:
    // public var analytics: AnalyticsService

    public init(
        configuration: EnvironmentConfigurationService,
        localStore: LocalStoreService,
        network: NetworkService,
        movieListService: MovieListService,
        moviesService: MoviesService
    ) {
        self.configuration = configuration
        self.localStore = localStore
        self.network = network
        self.movieListService = movieListService
        self.moviesService = moviesService
    }

    /// TMDB image base URL (from config), e.g. "https://image.tmdb.org/t/p".
    /// Exposed as a plain `String` so the app layer doesn't need to import AppConfiguration.
    public var imageBaseURL: String { configuration.bannerUrl() }
}

extension AppDependencies {
    /// Production container: real Info.plist config + UserDefaults/Keychain storage
    /// + a network service wired with both.
    public static func live() -> Self {
        let configuration = EnvironmentConfigurationService.live(bundle: .main)
        let localStore = LocalStoreService.live(keychainService: configuration.bundleID())
        let network = NetworkService.live(appConfiguration: configuration, localStore: localStore)
        return .init(
            configuration: configuration,
            localStore: localStore,
            network: network,
            movieListService: MovieListService.live(network),
            moviesService: MoviesService.live(network)
        )
    }

    /// Container for tests / SwiftUI previews: mock config + in-memory storage.
    public static func mock() -> Self {
        let configuration = EnvironmentConfigurationService.mock(bundleID: "com.innitial.preview")
        let localStore = LocalStoreService.inMemory()
        return .init(
            configuration: configuration,
            localStore: localStore,
            network: NetworkService.mock(appConfiguration: configuration, localStore: localStore),
            movieListService: MovieListService.mock(popularMovies: .sample),
            moviesService: MoviesService.mock(detail: .sample)
        )
    }
}
