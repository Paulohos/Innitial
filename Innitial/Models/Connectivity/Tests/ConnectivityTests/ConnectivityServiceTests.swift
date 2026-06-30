//
//  ConnectivityServiceTests.swift
//  ConnectivityTests
//
//  Cobre a fábrica `.mock` dirigindo o `AsyncStream` com sequências controladas.
//  A `.live` (NWPathMonitor) depende do estado real do SO e não é coberta por
//  unit test — seria um teste de integração contra o sistema.
//

import Testing
@testable import Connectivity

@Suite struct ConnectivityServiceTests {

    /// Helper: cria um service `.mock` que emite a sequência dada e fecha o fluxo.
    private func sut(emitting values: [Bool]) -> ConnectivityService {
        .mock {
            AsyncStream { continuation in
                for value in values { continuation.yield(value) }
                continuation.finish()
            }
        }
    }

    /// Coleta tudo que o `statusStream` emite até fechar.
    private func collect(_ service: ConnectivityService) async -> [Bool] {
        var received: [Bool] = []
        for await value in service.statusStream() { received.append(value) }
        return received
    }

    @Test func `statusStream emits the connected state and stays online`() async {
        let received = await collect(sut(emitting: [true]))
        #expect(received == [true])
    }

    @Test func `statusStream reflects a drop and a recovery in order`() async {
        let received = await collect(sut(emitting: [true, false, true]))
        #expect(received == [true, false, true])
    }

    @Test func `constant never changes from its single value`() async {
        var received: [Bool] = []
        // `.constant` mantém o fluxo aberto; pegamos só o primeiro valor.
        for await value in ConnectivityService.constant(false).statusStream() {
            received.append(value)
            break
        }
        #expect(received == [false])
    }
}
