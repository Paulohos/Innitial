import Foundation

/// High-level, type-safe facade over the storage backends. This is the type
/// you instantiate and inject into the app/modules.
///
/// You interact with it through key paths into ``StorageKeys``; the key itself
/// decides whether the value is read from / written to `UserDefaults` or the `Keychain`:
///
///     // declared once, in StorageKeys+Keys.swift:
///     extension StorageKeys {
///         var lastUsedLoginEmail: StorageKey<String> { .init("lastUsedLoginEmail", in: .userDefaults) }
///         var authToken: StorageKey<String>          { .init("authToken", in: .keychain) }
///     }
///
///     // used anywhere:
///     guard let email = try? store.load(\.lastUsedLoginEmail) else { return }
///     try store.save(token, for: \.authToken)   // routed to the Keychain automatically
///
/// Offline API responses are cached on disk via the URL-keyed
/// ``cacheResponse(_:for:now:)`` / ``cachedResponseData(for:maxAge:now:)`` API.
public struct LocalStoreService: Sendable {
    private let userDefaults: KeyValueStore
    private let keychain: KeyValueStore
    let fileSystem: KeyValueStore

    public init(
        userDefaults: KeyValueStore,
        keychain: KeyValueStore,
        fileSystem: KeyValueStore
    ) {
        self.userDefaults = userDefaults
        self.keychain = keychain
        self.fileSystem = fileSystem
    }

    private func store(for backend: StorageBackend) -> KeyValueStore {
        switch backend {
        case .userDefaults: userDefaults
        case .keychain: keychain
        case .fileSystem: fileSystem
        }
    }

    /// Reads the value for `keyPath`, or `nil` if nothing is stored.
    public func load<Value>(_ keyPath: KeyPath<StorageKeys, StorageKey<Value>>) throws -> Value? {
        let key = StorageKeys()[keyPath: keyPath]
        return try store(for: key.backend).value(Value.self, forKey: key.name)
    }

    /// Stores `value` for `keyPath`, routing to the key's backend.
    public func save<Value>(_ value: Value, for keyPath: KeyPath<StorageKeys, StorageKey<Value>>) throws {
        let key = StorageKeys()[keyPath: keyPath]
        try store(for: key.backend).set(value, forKey: key.name)
    }

    /// Removes the value for `keyPath`.
    public func remove<Value>(_ keyPath: KeyPath<StorageKeys, StorageKey<Value>>) throws {
        let key = StorageKeys()[keyPath: keyPath]
        try store(for: key.backend).removeValue(key.name)
    }
}

// MARK: - Required reads (throw instead of returning nil)

/// Error thrown when a value that *must* exist is missing.
public enum LocalStoreError: Error, Sendable, Equatable {
    case valueNotFound(key: String)
}

extension LocalStoreService {
    /// Like ``load(_:)`` but returns a **non-optional** value, throwing
    /// ``LocalStoreError/valueNotFound(key:)`` when nothing is stored.
    /// Use for keys that must exist in context (e.g. the auth token on an
    /// authenticated request).
    public func require<Value>(_ keyPath: KeyPath<StorageKeys, StorageKey<Value>>) throws -> Value {
        guard let value = try load(keyPath) else {
            throw LocalStoreError.valueNotFound(key: StorageKeys()[keyPath: keyPath].name)
        }
        return value
    }

    /// Like ``load(_:)`` but throws **your** error when nothing is stored, returning a
    /// non-optional value. Lets the caller map a missing value to a domain-specific error.
    ///
    ///     let token = try store.load(\.authToken, orThrow: NetworkServiceError.noAuthTokenInStorage)
    public func load<Value>(
        _ keyPath: KeyPath<StorageKeys, StorageKey<Value>>,
        orThrow error: @autoclosure () -> Error
    ) throws -> Value {
        guard let value = try load(keyPath) else { throw error() }
        return value
    }
}

// MARK: - Bulk removal

extension LocalStoreService {
    /// Wipes **everything** this service can reach: the app's UserDefaults domain,
    /// every Keychain item under its service, and every cached response file.
    ///
    /// ⚠️ The UserDefaults step clears the app's **entire** persistent domain — not
    /// just the keys written through this service (it uses `removePersistentDomain`).
    /// Use this for a factory reset or in tests, **not** for logout — for that use
    /// ``clearSession()``.
    public func removeAll() throws {
        try userDefaults.removeAll()
        try keychain.removeAll()
        try fileSystem.removeAll()
    }

    /// Clears session-scoped data on **logout**: the auth token (Keychain) and every
    /// cached API response (files). Convenience values like ``StorageKeys/lastUsedLoginEmail``
    /// and ``StorageKeys/hasSeenOnboarding`` are intentionally **kept**.
    public func clearSession() throws {
        try remove(\.authToken)
        try fileSystem.removeAll()
    }
}

// MARK: - Factories

extension LocalStoreService {
    /// Production store: `UserDefaults.standard` + Keychain under `keychainService`
    /// + a file-system cache for API responses (in Caches/ResponsesCache).
    public static func live(keychainService: String) -> Self {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let responsesDirectory = caches.appendingPathComponent("ResponsesCache", isDirectory: true)

        return .init(
            userDefaults: .userDefaults(),
            keychain: .keychain(service: keychainService),
            fileSystem: .fileSystem(directory: responsesDirectory)
        )
    }

    /// Volatile store for tests / previews — every backend in memory.
    public static func inMemory() -> Self {
        .init(
            userDefaults: .inMemory(),
            keychain: .inMemory(),
            fileSystem: .inMemory()
        )
    }
}
