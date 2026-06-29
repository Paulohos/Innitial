import Foundation

extension KeyValueStore {
    /// A volatile, in-memory store. Ideal for unit tests and SwiftUI previews:
    /// fast, deterministic, and never touches the real Keychain or UserDefaults.
    public static func inMemory() -> Self {
        let storage = InMemoryStorage()
        return .init(
            loadData: { key in storage.data(forKey: key) },
            saveData: { data, key in storage.set(data, forKey: key) },
            removeValue: { key in storage.removeValue(forKey: key) },
            removeAll: { storage.removeAll() }
        )
    }
}

/// Thread-safe dictionary backing ``KeyValueStore/inMemory()``.
/// Closures are synchronous, so a lock (not an actor) keeps the API non-async.
private final class InMemoryStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    func set(_ data: Data, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = data
    }

    func removeValue(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        storage.removeAll()
    }
}
