//
//  NetworkService+Dependency.swift
//  NetworkLayer
//
//  Registers the network service with swift-dependencies. Its live value pulls
//  the configuration and local store from the dependency graph.
//

import Dependencies

extension NetworkService: DependencyKey {
    public static var liveValue: NetworkService {
        @Dependency(\.configuration) var configuration
        @Dependency(\.localStore) var localStore
        return .live(appConfiguration: configuration, localStore: localStore)
    }

    public static var testValue: NetworkService {
        .mock(appConfiguration: .mock(), localStore: .inMemory())
    }
}

public extension DependencyValues {
    var networkService: NetworkService {
        get { self[NetworkService.self] }
        set { self[NetworkService.self] = newValue }
    }
}
