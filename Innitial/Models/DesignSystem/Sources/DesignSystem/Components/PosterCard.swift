import SwiftUI

/// A rounded movie poster image loaded from a URL, with a placeholder while it loads.
/// Model-agnostic so any feature can reuse it.
public struct PosterCard: View {
    private let imageURL: URL?
    private let width: CGFloat
    private let action: () -> Void

    public init(imageURL: URL?, width: CGFloat = 140, action: @escaping () -> Void = {}) {
        self.imageURL = imageURL
        self.width = width
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            poster
        }
        .buttonStyle(.scale)
    }

    private var poster: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty:
                placeholder.overlay(ProgressView().tint(.white))
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        // TMDB posters use a 2:3 aspect ratio.
        .frame(width: width, height: width * 3 / 2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.backgroundTop)
    }
}
