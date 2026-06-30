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
    @State private var path = NavigationPath()
    @State private var selectedMovie: Movie?

    public init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack(path: $path) {
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
            .navigationDestination(for: MovieCategory.self) { category in
                AllMoviesView(viewModel: viewModel.makeAllMoviesViewModel(for: category))
            }
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(viewModel: viewModel.makeMovieDetailViewModel(for: movie))
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
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
            carousel(.popular)
            carousel(.topRated)
            carousel(.nowPlaying)
            carousel(.upcoming)
        }
    }

    private func carousel(_ category: MovieCategory) -> some View {
        CarouselSection(
            title: category.title,
            onSeeAll: viewModel.hasMorePages(for: category) ? { path.append(category) } : nil
        ) {
            ForEach(viewModel.movies(for: category)) { movie in
                PosterCard(imageURL: viewModel.posterURL(for: movie), action: { selectedMovie = movie })
            }
        }
    }
}

#Preview {
    // In the preview context swift-dependencies serves `previewValue`
    // (sample data), so the carousels render without a network.
    HomeView(viewModel: HomeViewModel())
}
