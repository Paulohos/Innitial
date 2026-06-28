import Testing
@testable import AppDependencies

@Suite("AppDependencies")
struct AppDependenciesTests {

    @Test
    func `mock builds a container wired with the mock configuration`() {
        let dependencies = AppDependencies.mock()
        #expect(dependencies.configuration.bundleID() == "com.innitial.preview")
    }

    @Test
    func `live builds a container with a real system version`() {
        // .live() reads Bundle.main (no EnvironmentSetting in the test bundle, so the
        // plist-backed fields are empty), but it must construct without crashing and
        // expose a real OS version computed at access time.
        let dependencies = AppDependencies.live()
        #expect(!dependencies.configuration.systemVersion().isEmpty)
    }
}
