import SwiftUI

private struct AppDependenciesKey: EnvironmentKey {
    // Safe default for previews/tests; the app's root overrides it with `.live()`.
    static let defaultValue: AppDependencies = .mock()
}

public extension EnvironmentValues {
    /// The shared dependency container, injected at the app root and read by feature views.
    var dependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
