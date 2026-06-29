//
//  MovieDetailView.swift
//  Features
//

import SwiftUI
import DesignSystem
import Movies
import MovieListService

/// Movie detail screen, presented as a modal. Built per the design: backdrop header,
/// rating + title, overview, trailer button, cast, genres and recommendations.
struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            if let detail = viewModel.detail {
                VStack(alignment: .leading, spacing: 24) {
                    backdrop()

                    info(detail)
                        .padding(.horizontal)

                    Divider()
                        .overlay(Color.white.opacity(0.2))
                        .padding(.horizontal)

                    Text(detail.overview)
                        .padding(.horizontal)

                    trailerButton
                        .padding(.horizontal)

                    if !viewModel.cast.isEmpty {
                        castSection
                    }

                    genres(detail)
                        .padding(.horizontal)

                    if !viewModel.recommendations.isEmpty {
                        recommendations
                    }
                }
                .padding(.bottom, 40)
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
                    .padding()
            }
        }
        .foregroundStyle(.white)
        .background(Color.backgroundBottom.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topTrailing) { closeButton }
        .task { await viewModel.load() }
    }

    // MARK: - Sections

    private func backdrop() -> some View {
        // A full-width container drives the layout size; the image fills it and is
        // clipped. Otherwise a wide backdrop reports its own (over-screen) width and
        // pushes every section off to the left.
        Color.backgroundTop
            .frame(maxWidth: .infinity)
            .frame(height: 460)
            .overlay {
                AsyncImage(url: viewModel.backdropURL()) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.backgroundTop
                }
            }
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [.clear, .clear, Color.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func info(_ detail: MovieDetail) -> some View {
        HStack(alignment: .center, spacing: 16) {
            RatingRing(percent: viewModel.ratingPercent)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.titleWithYear)
                    .textStyle(.title)

                HStack(spacing: 6) {
                    Text(viewModel.releaseDateText)
                    if let runtime = viewModel.runtimeText {
                        Text("•")
                        Image(systemName: "clock")
                        Text(runtime)
                    }
                }
                .textStyle(.callout)
                .foregroundStyle(.white.opacity(0.7))
            }

            Spacer(minLength: 0)
        }
    }

    private var trailerButton: some View {
        Button(action: { /* TODO: tocar o trailer (fetch depois) */ }) {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill").font(.title3)
                Text("Assistir trailer")
            }
        }
        .buttonStyle(.primary)
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elenco principal")
                .textStyle(.sectionTitle)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(viewModel.cast) { member in
                        VStack(spacing: 8) {
                            AvatarView(imageURL: viewModel.castImageURL(member), size: 72)
                            Text(member.name)
                                .textStyle(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 72)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func genres(_ detail: MovieDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categoria(s)")
                .textStyle(.sectionTitle)

            HStack(spacing: 12) {
                ForEach(detail.genres) { genre in
                    Text(genre.name)
                        .textStyle(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.backgroundTop))
                }
            }
        }
    }

    private var recommendations: some View {
        CarouselSection(title: "Recomendações") {
            ForEach(viewModel.recommendations) { movie in
                PosterCard(imageURL: viewModel.posterURL(for: movie))
            }
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(.white, .black.opacity(0.4))
        }
        .padding()
    }
}

#Preview {
    MovieDetailView(viewModel: .preview())
}
