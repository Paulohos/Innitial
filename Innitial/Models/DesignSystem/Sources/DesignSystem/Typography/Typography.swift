import SwiftUI

/// The app's semantic text styles. Each maps to a system text style (so it scales
/// with Dynamic Type / accessibility sizes) with the Design System's weights.
///
/// Named `DSTextStyle` to avoid colliding with SwiftUI's `Font.TextStyle`.
/// Use through the `.textStyle(_:)` view modifier:
///
///     Text("Mais populares").textStyle(.sectionTitle)
///
/// or `Font.ds(_:)` when you need a raw `Font`.
public enum DSTextStyle: CaseIterable, Sendable {
    /// Screen-level title, e.g. "O que você quer assistir hoje?".
    case largeTitle
    /// Primary title.
    case title
    /// Carousel / section header, e.g. "Mais populares".
    case sectionTitle
    /// Emphasis within content.
    case headline
    /// Default running text.
    case body
    /// Secondary actions, e.g. the "Veja todos" button.
    case callout
    /// Supporting/metadata text.
    case caption

    public var font: Font {
        switch self {
        case .largeTitle:   .system(.largeTitle, design: .default, weight: .bold)
        case .title:        .system(.title, design: .default, weight: .bold)
        case .sectionTitle: .system(.title3, design: .default, weight: .bold)
        case .headline:     .system(.headline)
        case .body:         .system(.body)
        case .callout:      .system(.callout, design: .default, weight: .semibold)
        case .caption:      .system(.caption)
        }
    }
}

public extension Font {
    /// Raw `Font` token for a Design System text style — for APIs that take a `Font`.
    static func ds(_ style: DSTextStyle) -> Font { style.font }
}

public extension View {
    /// Applies a Design System text style to the view's text.
    func textStyle(_ style: DSTextStyle) -> some View {
        font(style.font)
    }
}
