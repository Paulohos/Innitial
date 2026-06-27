//
//  InnitialApp.swift
//  Innitial
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import SwiftUI
import AppDependencies

@main
struct InnitialApp: App {
    // Instância única dos services, montada no composition root.
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
        }
    }
}
