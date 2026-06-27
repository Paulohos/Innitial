import Foundation

public struct EnvironmentConfigurationService: Sendable{
    public let baseUrl: @Sendable () -> String
    public let bundleID: @Sendable () -> String
    public let termsOfUse: @Sendable () -> String
    public let privacyPolicy: @Sendable () -> String
    public let appStoreURL: @Sendable () -> String
}

extension EnvironmentConfigurationService {

    public static func live(bundle: Bundle = .main) -> Self {
        let settings = bundle.infoDictionary?["EnviromentSetting"] as? [String: Any] ?? [:]
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
            appStoreURL: { appStoreURL }
        )
   }


    public static func mock(
       baseUrl: String? = nil,
       bundleID: String? = nil,
       termsOfUse: String? = nil,
       privacyPolicy: String? = nil,
       appStoreURL: String? = nil
    ) -> Self {
        .init(
           baseUrl: { baseUrl ?? "" },
           bundleID: { bundleID ?? "" },
           termsOfUse: { termsOfUse ?? "" },
           privacyPolicy: { privacyPolicy ?? "" },
           appStoreURL: { appStoreURL ?? "" }
        )
    }
}
