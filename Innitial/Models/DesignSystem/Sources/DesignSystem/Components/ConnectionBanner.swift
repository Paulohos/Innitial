import SwiftUI

/// What the connection banner is currently saying. `nil` (no banner) is modelled
/// by the optional passed to `connectionBanner(state:)`.
public enum ConnectionBannerState: Sendable, Equatable {
    /// No internet — stays on screen until connectivity returns.
    case offline
    /// Connectivity just came back — a brief confirmation that auto-dismisses.
    case reconnected
}

/// A status pill that slides down from the top: dark surface with a coloured
/// icon + message. Red for offline, green for the reconnected confirmation.
///
/// Usually applied through the `connectionBanner(state:)` modifier rather than
/// instantiated directly.
public struct ConnectionBanner: View {
    private let state: ConnectionBannerState

    public init(state: ConnectionBannerState) {
        self.state = state
    }

    private var iconName: String {
        switch state {
        case .offline: "wifi.slash"
        case .reconnected: "wifi"
        }
    }

    private var message: String {
        switch state {
        case .offline: "Sem conexão com a internet"
        case .reconnected: "Conexão restabelecida"
        }
    }

    private var accent: Color {
        switch state {
        case .offline: .statusError
        case .reconnected: .statusOnline
        }
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(accent)
            Text(message)
                .textStyle(.callout)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.bannerSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(accent)
                .frame(height: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

public extension View {
    /// Overlays a connection banner that slides in from the top whenever `state`
    /// is non-nil, and slides back out when it returns to `nil`. The banner sits
    /// above everything (including navigation) and respects the top safe area.
    func connectionBanner(state: ConnectionBannerState?) -> some View {
        overlay(alignment: .top) {
            if let state {
                ConnectionBanner(state: state)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.3), value: state)
    }
}

#Preview("Offline") {
    Color.backgroundBottom
        .ignoresSafeArea()
        .connectionBanner(state: .offline)
}

#Preview("Reconnected") {
    Color.backgroundBottom
        .ignoresSafeArea()
        .connectionBanner(state: .reconnected)
}
