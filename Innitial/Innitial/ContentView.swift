//
//  ContentView.swift
//  Innitial
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import SwiftUI
import Home

struct ContentView: View {
    // Fora de testes/previews o app roda no contexto "live" do swift-dependencies,
    // então `HomeViewModel()` resolve o grafo real (config → network → services)
    // sozinho — sem container nem bootstrap.
    @State private var viewModel = HomeViewModel()
    // Observa a conectividade e dirige o banner global de "sem conexão".
    @State private var connectivity = ConnectivityViewModel()

    var body: some View {
        HomeView(viewModel: viewModel)
            .connectionBanner(for: connectivity)
            .task { await connectivity.observe() }
    }
}

#Preview {
    ContentView()
}
