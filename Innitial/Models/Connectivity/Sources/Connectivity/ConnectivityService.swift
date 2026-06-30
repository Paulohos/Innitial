//
//  ConnectivityService.swift
//  Connectivity
//
//  Observa a conectividade de rede do dispositivo e a expõe como um fluxo de
//  `Bool` (conectado / desconectado). Segue o padrão struct-of-closures do app:
//  um `Sendable` de closures, com fábricas `.live` / `.mock` / `.constant`.
//

import Foundation
import Network

public struct ConnectivityService: Sendable {
    /// Emite o estado atual de conectividade ao começar e, depois, `true`/`false`
    /// a cada mudança. O fluxo é infinito enquanto o consumidor o mantiver vivo.
    public let statusStream: @Sendable () -> AsyncStream<Bool>

    public init(statusStream: @escaping @Sendable () -> AsyncStream<Bool>) {
        self.statusStream = statusStream
    }
}

public extension ConnectivityService {
    /// Produção: usa `NWPathMonitor` numa fila dedicada. Cada `statusStream()`
    /// cria um monitor próprio que é cancelado quando o fluxo termina.
    static func live() -> Self {
        .init(
            statusStream: {
                AsyncStream { continuation in
                    let monitor = NWPathMonitor()
                    let queue = DispatchQueue(label: "com.innitial.connectivity.monitor")

                    monitor.pathUpdateHandler = { path in
                        continuation.yield(path.status == .satisfied)
                    }
                    continuation.onTermination = { _ in
                        monitor.cancel()
                    }
                    monitor.start(queue: queue)
                }
            }
        )
    }

    /// Testes/preview: repassa um `AsyncStream` controlado pelo chamador.
    static func mock(_ stream: @escaping @Sendable () -> AsyncStream<Bool>) -> Self {
        .init(statusStream: stream)
    }

    /// Testes/preview: emite um único valor fixo e nunca muda (o fluxo fica aberto).
    /// `.constant(true)` nunca dispara o banner de "sem conexão".
    static func constant(_ value: Bool) -> Self {
        .init(
            statusStream: {
                AsyncStream { continuation in
                    continuation.yield(value)
                }
            }
        )
    }
}
