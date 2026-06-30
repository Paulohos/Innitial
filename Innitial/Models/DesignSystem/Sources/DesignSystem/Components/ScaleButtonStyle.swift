import SwiftUI

/// A button style that shrinks its content slightly while pressed, giving a
/// tactile "press" feedback. Reusable for any tappable element.
public struct ScaleButtonStyle: ButtonStyle {
    private let pressedScale: CGFloat

    public init(pressedScale: CGFloat = 0.95) {
        self.pressedScale = pressedScale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == ScaleButtonStyle {
    /// Shrinks slightly while pressed (default 0.95).
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }

    /// Shrinks to `pressedScale` while pressed.
    static func scale(pressedScale: CGFloat) -> ScaleButtonStyle {
        ScaleButtonStyle(pressedScale: pressedScale)
    }
}
