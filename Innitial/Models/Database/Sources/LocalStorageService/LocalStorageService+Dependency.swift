//
//  LocalStorageService+Dependency.swift
//  LocalStorageService
//
//  Registers the local store with swift-dependencies.
//

import Dependencies
import Foundation

extension LocalStorageService: DependencyKey {
    /// Production: UserDefaults + Keychain, keyed by the app's bundle identifier.
    public static var liveValue: LocalStorageService {
        .live(keychainService: Bundle.main.bundleIdentifier ?? "Innitial")
    }
    /// Tests/previews: in-memory storage.
    public static var testValue: LocalStorageService { .inMemory() }
}

public extension DependencyValues {
    var localStorageService: LocalStorageService {
        get { self[LocalStorageService.self] }
        set { self[LocalStorageService.self] = newValue }
    }
}
