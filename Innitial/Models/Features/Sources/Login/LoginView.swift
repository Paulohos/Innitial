//
//  LoginView.swift
//  Features
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import SwiftUI

public struct LoginView: View {
    // ViewModel injetado pronto (instanciado na raiz do app).
    private let viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            Section("Login") {
                TextField("E-mail", text: $viewModel.email)
                SecureField("Senha", text: $viewModel.password)
                Button("Entrar") {
                    Task { await viewModel.login() }
                }
            }
            if viewModel.isLoggedIn {
                Label("Autenticado", systemImage: "checkmark.seal.fill")
            }
        }
    }
}

// No Xcode, adicione o preview (precisa `import Database` para o `.inMemory()`):
//
//   #Preview {
//       LoginView(viewModel: LoginViewModel(store: .inMemory()))
//   }
