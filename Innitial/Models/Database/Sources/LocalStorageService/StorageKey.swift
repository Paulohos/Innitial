import Foundation

/// Where a value is persisted.
public enum StorageBackend: Sendable {
    /// Plain app preferences (`UserDefaults`).
    case userDefaults
    /// Secure storage (`Keychain`) — for tokens, credentials, secrets.
    case keychain
    /// Files on disk — for large blobs / cached API responses (JSON).
    case fileSystem
}

/// A typed, self-describing storage key.
///
/// A key knows its underlying name, the `Value` type it stores, and which
/// backend it lives in — so the call site can't mix up types or pick the wrong store.
public struct StorageKey<Value: Codable & Sendable>: Sendable {
    public let name: String
    public let backend: StorageBackend

    public init(_ name: String, in backend: StorageBackend) {
        self.name = name
        self.backend = backend
    }
}

/// Namespace for typed storage keys. Declare keys by extending it
/// (the same pattern as SwiftUI's `EnvironmentValues`):
///
///     extension StorageKeys {
///         var lastUsedLoginEmail: StorageKey<String> { .init("lastUsedLoginEmail", in: .userDefaults) }
///         var authToken: StorageKey<String>          { .init("authToken", in: .keychain) }
///     }
///
/// Then access them by key path: `try store.load(\.lastUsedLoginEmail)`.
public struct StorageKeys: Sendable {
    public init() {}
}
