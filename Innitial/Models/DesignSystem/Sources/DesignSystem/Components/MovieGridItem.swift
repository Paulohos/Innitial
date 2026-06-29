import SwiftUI

/// A grid cell: the poster (2:3, fills its column) with the movie title below it,
/// limited to two lines. Tappable (shrinks on press); `action` is optional.
public struct MovieGridItem: View {
    private let imageURL: URL?
    private let title: String
    private let action: () -> Void

    public init(imageURL: URL?, title: String, action: @escaping () -> Void = {}) {
        self.imageURL = imageURL
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                PosterImage(imageURL: imageURL)
                    .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .textStyle(.callout)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.scale)
    }
}
