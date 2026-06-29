import SwiftUI

/// The async-loaded poster artwork (image + placeholder), without any sizing —
/// callers apply their own frame / aspect ratio / clip. Shared by `PosterCard`
/// (fixed width) and `MovieGridItem` (flexible width).
struct PosterImage: View {
    let imageURL: URL?

    var body: some View {
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
    }

    private var placeholder: some View {
        Rectangle().fill(Color.backgroundTop)
    }
}
