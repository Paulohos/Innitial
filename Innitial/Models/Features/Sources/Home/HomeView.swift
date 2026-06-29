//
//  SwiftUIView.swift
//  Features
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//

import SwiftUI
import DesignSystem
import MovieListService

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HomeHeader()
                    .padding(.horizontal)

                content
            }
            .padding(.vertical)
        }
        .foregroundStyle(.white)
        .appBackground()
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            carousel(title: "Mais populares", movies: viewModel.popular)
            carousel(title: "Mais bem avaliados", movies: viewModel.topRated)
            carousel(title: "Em cartaz", movies: viewModel.nowPlaying)
            carousel(title: "Em breve", movies: viewModel.upcoming)
        }
    }

    private func carousel(title: String, movies: [Movie]) -> some View {
        CarouselSection(title: title, onSeeAll: { /* TODO: navegar para a lista completa */ }) {
            ForEach(movies) { movie in
                PosterCard(imageURL: viewModel.posterURL(for: movie))
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(
        movieListService: .mock(
            popularMovies: .sample,
            topRatedMovies: .sample,
            upcomingMovies: .sample,
            nowPlayingMovies: .sample
        ),
        imageBaseURL: "https://image.tmdb.org/t/p"
    ))
}
