//
//  AllMoviesView.swift
//  Features
//

import SwiftUI
import DesignSystem
import MovieListService

/// Full, paginated list of a category's movies — a 2-column grid with infinite scroll.
struct AllMoviesView: View {
    @State private var viewModel: AllMoviesViewModel
    @State private var selectedMovie: Movie?

    init(viewModel: AllMoviesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        content
            .foregroundStyle(.white)
            .appBackground()
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(viewModel: viewModel.makeMovieDetailViewModel(for: movie))
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .tint(.white)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.movies.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.largeTitle)
                Text(viewModel.errorMessage ?? "Não foi possível carregar os filmes.")
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white.opacity(0.8))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.movies) { movie in
                        MovieGridItem(
                            imageURL: viewModel.posterURL(for: movie),
                            title: movie.title,
                            action: { selectedMovie = movie }
                        )
                        .task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }
                    }
                }
                .padding(.horizontal)

                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 24)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllMoviesView(viewModel: AllMoviesViewModel(category: .popular, firstPage: .sample))
    }
}
