import SwiftUI

/// A grid cell: just the poster (2:3, fills its column). The artwork already
/// carries the title, so no separate label. Tappable (shrinks on press); `action`
/// is optional.
public struct MovieGridItem: View {
    private let imageURL: URL?
    private let action: () -> Void

    public init(imageURL: URL?, action: @escaping () -> Void = {}) {
        self.imageURL = imageURL
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            PosterImage(imageURL: imageURL)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.scale)
    }
}
