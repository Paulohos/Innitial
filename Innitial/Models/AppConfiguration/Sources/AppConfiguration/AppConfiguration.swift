import Foundation

public struct EnvironmentConfigurationService: Sendable {
    public let baseUrl: @Sendable () -> String
    public let bundleID: @Sendable () -> String
    public let termsOfUse: @Sendable () -> String
    public let privacyPolicy: @Sendable () -> String
    public let appStoreURL: @Sendable () -> String
    /// App version (CFBundleShortVersionString), e.g. "1.0".
    public let releaseVersionNumber: @Sendable () -> String
    /// OS version, e.g. "17.0".
    public let systemVersion: @Sendable () -> String
    /// Current time zone identifier, e.g. "America/Sao_Paulo".
    public let timeZoneIdentifier: @Sendable () -> String
}

extension EnvironmentConfigurationService {

    public static func live(bundle: Bundle = .main) -> Self {
        let settings = bundle.infoDictionary?["EnvironmentSetting"] as? [String: Any] ?? [:]
        return .live(settings: settings, releaseVersionNumber: bundle.releaseVersionNumber ?? "")
    }

    /// Builds the configuration from an already-extracted settings dictionary.
    /// Kept `internal` so tests can exercise the parsing without a real `Bundle`.
    ///
    /// The `String` values are resolved up front (not captured as `Any`) so the
    /// `@Sendable` accessor closures only capture `Sendable` `String`s.
    static func live(settings: [String: Any], releaseVersionNumber: String) -> Self {
        func value(_ name: String) -> String { settings[name] as? String ?? "" }

        let baseUrl = value("baseURL")
        let bundleID = value("bundleId")
        let termsOfUse = value("termsOfUseURL")
        let privacyPolicy = value("privacyPolicyUrl")
        let appStoreURL = value("appStoreURL")

        return .init(
            baseUrl: { baseUrl },
            bundleID: { bundleID },
            termsOfUse: { termsOfUse },
            privacyPolicy: { privacyPolicy },
            appStoreURL: { appStoreURL },
            releaseVersionNumber: { releaseVersionNumber },
            systemVersion: {
                let v = ProcessInfo.processInfo.operatingSystemVersion
                return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
            },
            // computed live so it reflects the device's current time zone
            timeZoneIdentifier: { TimeZone.current.identifier }
        )
    }


    public static func mock(
       baseUrl: String? = nil,
       bundleID: String? = nil,
       termsOfUse: String? = nil,
       privacyPolicy: String? = nil,
       appStoreURL: String? = nil,
       releaseVersionNumber: String? = nil,
       systemVersion: String? = nil,
       timeZoneIdentifier: String? = nil
    ) -> Self {
        .init(
           baseUrl: { baseUrl ?? "" },
           bundleID: { bundleID ?? "" },
           termsOfUse: { termsOfUse ?? "" },
           privacyPolicy: { privacyPolicy ?? "" },
           appStoreURL: { appStoreURL ?? "" },
           releaseVersionNumber: { releaseVersionNumber ?? "" },
           systemVersion: { systemVersion ?? "" },
           timeZoneIdentifier: { timeZoneIdentifier ?? "" }
        )
    }
}

extension Bundle {
    /// The app's release version (CFBundleShortVersionString), e.g. "1.0".
    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
