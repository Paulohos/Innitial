import SwiftUI

/// A circular rating badge: a brand-colored progress ring around a percentage,
/// e.g. a movie's vote average shown as `82%`.
public struct RatingRing: View {
    private let percent: Int
    private let size: CGFloat

    public init(percent: Int, size: CGFloat = 56) {
        self.percent = max(0, min(100, percent))
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle().fill(Color.backgroundBottom)
            Circle().stroke(Color.white.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(Color.brandPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)%")
                .font(.system(size: size * 0.28, weight: .bold))
        }
        .frame(width: size, height: size)
    }
}
