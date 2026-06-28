import Foundation

/// Shared JSON coders for the storage layer, reused instead of allocating a new
/// coder on every read/write. `JSONEncoder`/`JSONDecoder` are `Sendable`.
let sharedJSONEncoder = JSONEncoder()
let sharedJSONDecoder = JSONDecoder()

/// Low-level, single-backend key/value engine in the "struct of closures" style.
///
/// `KeyValueStore` operates over raw `Data` so the same type can back different
/// storage engines (UserDefaults, Keychain, file system, in-memory). Use the generic
/// `Codable` helpers (`set(_:forKey:)` / `value(_:forKey:)`) to store primitives
/// (`Int`, `String`, `Bool`, ...) or custom `Codable` objects with one uniform API.
///
/// You normally don't use this directly — `LocalStoreService` composes these
/// (UserDefaults + Keychain + file system) and routes by key. Pick a backend via a factory:
/// - ``userDefaults(_:domainName:)``
/// - ``keychain(service:accessGroup:)``
/// - ``fileSystem(directory:)``
/// - ``inMemory()`` (for tests / previews)
public struct KeyValueStore: Sendable {
    /// Reads the raw data stored for `key`, or `nil` if nothing is stored.
    public var loadData: @Sendable (_ key: String) throws -> Data?
    /// Writes raw `data` for `key`, overwriting any existing value.
    public var saveData: @Sendable (_ data: Data, _ key: String) throws -> Void
    /// Removes any value stored for `key`. A missing key is not an error.
    public var removeValue: @Sendable (_ key: String) throws -> Void
    /// Removes every value owned by this store.
    public var removeAll: @Sendable () throws -> Void

    public init(
        loadData: @escaping @Sendable (_ key: String) throws -> Data?,
        saveData: @escaping @Sendable (_ data: Data, _ key: String) throws -> Void,
        removeValue: @escaping @Sendable (_ key: String) throws -> Void,
        removeAll: @escaping @Sendable () throws -> Void
    ) {
        self.loadData = loadData
        self.saveData = saveData
        self.removeValue = removeValue
        self.removeAll = removeAll
    }
}

// MARK: - Codable convenience

extension KeyValueStore {
    /// Decodes and returns the value stored for `key`, or `nil` if absent.
    public func value<Value: Decodable>(
        _ type: Value.Type = Value.self,
        forKey key: String,
        decoder: JSONDecoder? = nil
    ) throws -> Value? {
        guard let data = try loadData(key) else { return nil }
        return try (decoder ?? sharedJSONDecoder).decode(Value.self, from: data)
    }

    /// Encodes `value` and stores it under `key`.
    public func set<Value: Encodable>(
        _ value: Value,
        forKey key: String,
        encoder: JSONEncoder? = nil
    ) throws {
        let data = try (encoder ?? sharedJSONEncoder).encode(value)
        try saveData(data, key)
    }

    /// Removes the value stored for `key`.
    public func remove(forKey key: String) throws {
        try removeValue(key)
    }
}
