import SwiftUI

/// A circular profile avatar loaded from a URL, falling back to a person icon
/// placeholder. Model-agnostic so any feature can reuse it.
public struct AvatarView: View {
    private let imageURL: URL?
    private let size: CGFloat

    public init(imageURL: URL? = nil, size: CGFloat = 48) {
        self.imageURL = imageURL
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }

    private var placeholder: some View {
        ZStack {
            Color.backgroundTop
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding(size * 0.25)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
