//
//  LocalStoreService+Dependency.swift
//  LocalStoreService
//
//  Registers the local store with swift-dependencies.
//

import Dependencies
import Foundation

extension LocalStoreService: DependencyKey {
    /// Production: UserDefaults + Keychain, keyed by the app's bundle identifier.
    public static var liveValue: LocalStoreService {
        .live(keychainService: Bundle.main.bundleIdentifier ?? "Innitial")
    }
    /// Tests/previews: in-memory storage.
    public static var testValue: LocalStoreService { .inMemory() }
}

public extension DependencyValues {
    var localStore: LocalStoreService {
        get { self[LocalStoreService.self] }
        set { self[LocalStoreService.self] = newValue }
    }
}
