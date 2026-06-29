import SwiftUI

/// The app's primary call-to-action button style: a full-width, capsule-shaped,
/// brand-colored button with the headline font and a press feedback.
///
/// Apply it to a plain SwiftUI `Button` and just provide the content:
///
///     Button(action: play) {
///         Label("Assistir trailer", systemImage: "play.circle.fill")
///     }
///     .buttonStyle(.primary)
public struct PrimaryButtonStyle: ButtonStyle {
    private let background: Color

    public init(background: Color = .brandPurple) {
        self.background = background
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.headline)
            .foregroundStyle(.white)
            .tint(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Capsule().fill(background))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Brand primary CTA (capsule, brand purple).
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// Primary CTA with a custom background color.
    static func primary(background: Color) -> PrimaryButtonStyle {
        PrimaryButtonStyle(background: background)
    }
}
