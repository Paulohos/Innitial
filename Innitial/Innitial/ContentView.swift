//
//  ContentView.swift
//  Innitial
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import SwiftUI
import AppDependencies
import LocalStoreService
import Login

struct ContentView: View {
    // O ViewModel é dono da tela; o app injeta o store (database) nele.
    @State private var loginViewModel: LoginViewModel

    init(dependencies: AppDependencies) {
        _loginViewModel = State(
            initialValue: LoginViewModel(store: dependencies.localStore)
        )
    }

    var body: some View {
        LoginView(viewModel: loginViewModel)
    }
}

#Preview {
    ContentView(dependencies: .mock())
}
