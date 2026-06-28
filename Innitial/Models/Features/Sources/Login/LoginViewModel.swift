//
//  LoginViewModel.swift
//  Features
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import Foundation
import LocalStoreService

@MainActor
@Observable
public final class LoginViewModel {
    public var email: String
    public var password: String = ""
    public private(set) var isLoggedIn = false

    private let store: LocalStoreService

    public init(store: LocalStoreService) {
        self.store = store
        // pré-preenche com o último e-mail usado (UserDefaults)
        self.email = (try? store.load(\.lastUsedLoginEmail)) ?? ""
    }

    /// Lê do UserDefaults via a key tipada — a feature não sabe (nem precisa) qual backend é.
    public var hasSeenOnboarding: Bool {
        (try? store.load(\.hasSeenOnboarding)) ?? false
    }

    public func login() async {
        // TODO: trocar pela chamada real ao NetworkLayer e usar o token retornado.
        let token = "token-for-\(email)"

        try? store.save(email, for: \.lastUsedLoginEmail)  // → UserDefaults
        try? store.save(token, for: \.authToken)           // → Keychain
        isLoggedIn = true
    }
}
