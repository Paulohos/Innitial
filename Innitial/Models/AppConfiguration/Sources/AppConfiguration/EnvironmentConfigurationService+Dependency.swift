//
//  EnvironmentConfigurationService+Dependency.swift
//  AppConfiguration
//
//  Registers the configuration (and the derived image base URL) with
//  swift-dependencies, so any layer can read them via `@Dependency`.
//

import Dependencies

extension EnvironmentConfigurationService: DependencyKey {
    /// Production: read from the main bundle's Info.plist.
    public static var liveValue: EnvironmentConfigurationService { .live(bundle: .main) }
    /// Tests/previews: empty configuration (override per test when needed).
    public static var testValue: EnvironmentConfigurationService { .mock() }
}

public extension DependencyValues {
    var configuration: EnvironmentConfigurationService {
        get { self[EnvironmentConfigurationService.self] }
        set { self[EnvironmentConfigurationService.self] = newValue }
    }
}
