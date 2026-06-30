import SwiftUI

public extension Color {
    /// Brand purple — `#8000FF`. Used for the app's accent and top-of-screen glow.
    static let brandPurple = Color(hex: 0x8000FF)

    /// Upper shade of the app's dark background gradient — `#303243`.
    static let backgroundTop = Color(hex: 0x303243)

    /// Lower shade of the app's dark background gradient — `#15151D`.
    static let backgroundBottom = Color(hex: 0x15151D)

    /// Surface for transient status banners (e.g. "sem conexão") — `#1C1C1E`.
    static let bannerSurface = Color(hex: 0x1C1C1E)

    /// Error / offline accent — iOS system red `#FF3B30`.
    static let statusError = Color(hex: 0xFF3B30)

    /// Success / reconnected accent — iOS system green `#34C759`.
    static let statusOnline = Color(hex: 0x34C759)
}
