import SwiftUI

/// A titled horizontal carousel: a section title with an optional "Veja todos >"
/// button on the same line, followed by a horizontally scrolling row of content.
///
/// Reusable for any horizontal list (popular movies, top rated, etc.):
///
///     CarouselSection(title: "Mais populares", onSeeAll: { ... }) {
///         ForEach(movies) { PosterCard(imageURL: ...) }
///     }
public struct CarouselSection<Content: View>: View {
    private let title: String
    private let seeAllTitle: String
    private let onSeeAll: (() -> Void)?
    private let content: Content

    public init(
        title: String,
        seeAllTitle: String = "Veja todos",
        onSeeAll: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.seeAllTitle = seeAllTitle
        self.onSeeAll = onSeeAll
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .textStyle(.sectionTitle)

                Spacer()

                if let onSeeAll {
                    Button(action: onSeeAll) {
                        HStack(spacing: 4) {
                            Text(seeAllTitle)
                            Image(systemName: "chevron.right")
                        }
                        .textStyle(.callout)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}
