import SwiftUI

public extension LinearGradient {
    /// Top-of-screen brand glow: `brandPurple` fading to clear over the upper 40%.
    static let brandGlow = LinearGradient(
        stops: [
            .init(color: .brandPurple, location: 0),
            .init(color: .clear, location: 0.4)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// The app's dark base background: `backgroundTop` settling into `backgroundBottom`.
    static let appBase = LinearGradient(
        stops: [
            .init(color: .backgroundTop, location: 0),
            .init(color: .backgroundBottom, location: 0.25)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension View {
    /// Applies the app's standard screen background: the dark base gradient with the
    /// brand purple glow layered on top. Fills the available space and ignores safe areas.
    func appBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient.brandGlow.ignoresSafeArea())
            .background(LinearGradient.appBase.ignoresSafeArea())
    }
}
