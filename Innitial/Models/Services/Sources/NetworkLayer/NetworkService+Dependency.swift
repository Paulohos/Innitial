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
        @Dependency(\.localStorageService) var localStorageService
        return .live(appConfiguration: configuration, localStorageService: localStorageService)
    }

    public static var testValue: NetworkService {
        .mock(appConfiguration: .mock(), localStorageService: .inMemory())
    }
}

public extension DependencyValues {
    var networkService: NetworkService {
        get { self[NetworkService.self] }
        set { self[NetworkService.self] = newValue }
    }
}
