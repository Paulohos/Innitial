//
//  ConnectivityService+Dependency.swift
//  Connectivity
//
//  Registra o serviço de conectividade com swift-dependencies, para que qualquer
//  camada possa observar a rede via `@Dependency(\.connectivity)`.
//

import Dependencies

extension ConnectivityService: DependencyKey {
    /// Produção: monitora a rede real via `NWPathMonitor`.
    public static var liveValue: ConnectivityService { .live() }
    /// Testes/previews: assume conectado (override por teste quando precisar simular queda).
    public static var testValue: ConnectivityService { .constant(true) }
    /// Previews: assume conectado, então o banner não aparece.
    public static var previewValue: ConnectivityService { .constant(true) }
}

public extension DependencyValues {
    var connectivity: ConnectivityService {
        get { self[ConnectivityService.self] }
        set { self[ConnectivityService.self] = newValue }
    }
}
