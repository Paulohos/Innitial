import Foundation

extension KeyValueStore {
    /// A store backed by `UserDefaults`.
    ///
    /// - Parameters:
    ///   - defaults: The `UserDefaults` instance to use (e.g. `.standard` or a suite).
    ///   - domainName: The persistent domain cleared by ``removeAll``. Defaults to the
    ///     app's bundle identifier (the domain of `.standard`). For a suite, pass its `suiteName`.
    public static func userDefaults(
        _ defaults: UserDefaults = .standard,
        domainName: String? = Bundle.main.bundleIdentifier
    ) -> Self {
        // `UserDefaults` is thread-safe but not `Sendable`, so box it to capture
        // it inside the `@Sendable` closures under Swift 6 strict concurrency.
        let defaults = UncheckedSendable(defaults)

        return .init(
            loadData: { key in
                defaults.value.data(forKey: key)
            },
            saveData: { data, key in
                defaults.value.set(data, forKey: key)
            },
            removeValue: { key in
                defaults.value.removeObject(forKey: key)
            },
            removeAll: {
                guard let domainName else { return }
                defaults.value.removePersistentDomain(forName: domainName)
            }
        )
    }
}

/// Wraps a non-`Sendable` value so it can be captured by `@Sendable` closures.
/// Use only for values that are themselves thread-safe (e.g. `UserDefaults`).
struct UncheckedSendable<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}
