import Foundation

/// App-wide storage keys, declared here so every module (Features, etc.)
/// can reference them without re-declaring. Access by key path, e.g.
/// `try store.load(\.authToken)`.
public extension StorageKeys {
    /// Last e-mail typed on the login screen — convenience, not sensitive.
    var lastUsedLoginEmail: StorageKey<String> { .init("lastUsedLoginEmail", in: .userDefaults) }

    /// Authorization token — sensitive, kept in the Keychain.
    var authToken: StorageKey<String> { .init("authToken", in: .keychain) }

    /// Whether the user has already completed onboarding.
    var hasSeenOnboarding: StorageKey<Bool> { .init("hasSeenOnboarding", in: .userDefaults) }
}
