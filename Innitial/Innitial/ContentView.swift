//
//  ContentView.swift
//  Innitial
//
//  Created by Paulo Henrique Oliveira Souza on 27/06/26.
//

import SwiftUI
import AppDependencies
import Home
import MovieListService
import Movies

struct ContentView: View {
    // O ContentView é o composition root: monta o ViewModel da tela inicial
    // injetando só o serviço de que o Home precisa.
    private let homeViewModel: HomeViewModel

    init(dependencies: AppDependencies) {
        homeViewModel = HomeViewModel(
            movieListService: dependencies.movieListService,
            moviesService: dependencies.moviesService,
            imageBaseURL: dependencies.imageBaseURL
        )
    }

    var body: some View {
        HomeView(viewModel: homeViewModel)
    }
}

#Preview {
    ContentView(dependencies: .mock())
}
