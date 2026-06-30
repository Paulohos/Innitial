//
//  ConnectivityViewModel.swift
//  Features
//
//  Consome o fluxo de conectividade e o traduz no estado do banner global:
//  mostra "sem conexão" enquanto offline e um flash verde de "reconectado" por
//  alguns segundos quando a rede volta.
//

import Foundation
import SwiftUI
import Connectivity
import Dependencies
import DesignSystem

@MainActor
@Observable
public final class ConnectivityViewModel {

    /// O que o banner deve mostrar agora; `nil` = nada na tela.
    public private(set) var bannerState: ConnectionBannerState?

    /// Quanto tempo o flash verde de "reconectado" fica antes de sumir.
    private let reconnectedDisplay: Duration

    @ObservationIgnored @Dependency(\.connectivity) private var connectivity

    public init(reconnectedDisplay: Duration = .seconds(2)) {
        self.reconnectedDisplay = reconnectedDisplay
    }

    /// Observa a conectividade até a Task ser cancelada. Seguro chamar de `.task`.
    public func observe() async {
        var wasOffline = false
        for await isConnected in connectivity.statusStream() {
            if !isConnected {
                bannerState = .offline
                wasOffline = true
            } else if wasOffline {
                wasOffline = false
                bannerState = .reconnected
                try? await Task.sleep(for: reconnectedDisplay)
                // Só limpa se ainda estiver no flash verde (não derruba um novo offline).
                if bannerState == .reconnected { bannerState = nil }
            }
        }
    }
}

public extension View {
    /// Overlays the global connection banner driven by a `ConnectivityViewModel`.
    /// Lives in `Home` so the app only needs to `import Home` (not `DesignSystem`).
    func connectionBanner(for viewModel: ConnectivityViewModel) -> some View {
        connectionBanner(state: viewModel.bannerState)
    }
}
