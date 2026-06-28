import Testing
@testable import AppConfiguration

@Suite("EnvironmentConfigurationService")
struct EnvironmentConfigurationServiceTests {

    @Test
    func `live maps the settings dictionary onto the typed accessors`() {
        let settings: [String: Any] = [
            "baseURL": "https://api.test",
            "bundleId": "com.innitial.test",
            "termsOfUseURL": "https://terms",
            "privacyPolicyUrl": "https://privacy",
            "appStoreURL": "https://store"
        ]

        let config = EnvironmentConfigurationService.live(settings: settings, releaseVersionNumber: "1.2")

        #expect(config.baseUrl() == "https://api.test")
        #expect(config.bundleID() == "com.innitial.test")
        #expect(config.termsOfUse() == "https://terms")
        #expect(config.privacyPolicy() == "https://privacy")
        #expect(config.appStoreURL() == "https://store")
        #expect(config.releaseVersionNumber() == "1.2")
    }

    @Test
    func `missing settings fall back to empty strings`() {
        let config = EnvironmentConfigurationService.live(settings: [:], releaseVersionNumber: "")

        #expect(config.baseUrl() == "")
        #expect(config.bundleID() == "")
        #expect(config.appStoreURL() == "")
        #expect(config.releaseVersionNumber() == "")
    }

    @Test
    func `non string values are ignored and fall back to empty`() {
        let settings: [String: Any] = ["baseURL": 42]
        let config = EnvironmentConfigurationService.live(settings: settings, releaseVersionNumber: "")
        #expect(config.baseUrl() == "")
    }

    @Test
    func `system version and time zone are computed live and non empty`() {
        let config = EnvironmentConfigurationService.live(settings: [:], releaseVersionNumber: "")
        #expect(!config.systemVersion().isEmpty)
        #expect(!config.timeZoneIdentifier().isEmpty)
    }

    @Test
    func `mock defaults every field to an empty string`() {
        let config = EnvironmentConfigurationService.mock()
        #expect(config.baseUrl() == "")
        #expect(config.bundleID() == "")
        #expect(config.systemVersion() == "")
    }
}
