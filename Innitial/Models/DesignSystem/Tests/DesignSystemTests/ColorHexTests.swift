import Testing
import SwiftUI
@testable import DesignSystem

@Suite("Color(hex:)")
struct ColorHexTests {

    @Test
    func `hex maps to the matching rgb components`() {
        #expect(Color(hex: 0xFFFFFF) == Color(red: 1, green: 1, blue: 1))
        #expect(Color(hex: 0x000000) == Color(red: 0, green: 0, blue: 0))
        #expect(Color(hex: 0x8000FF) == Color(red: 128 / 255, green: 0, blue: 1))
    }

    @Test
    func `each channel is isolated to its own byte`() {
        #expect(Color(hex: 0xFF0000) == Color(red: 1, green: 0, blue: 0))
        #expect(Color(hex: 0x00FF00) == Color(red: 0, green: 1, blue: 0))
        #expect(Color(hex: 0x0000FF) == Color(red: 0, green: 0, blue: 1))
    }

    @Test
    func `tokens use their documented hex values`() {
        #expect(Color.brandPurple == Color(hex: 0x8000FF))
        #expect(Color.backgroundTop == Color(hex: 0x303243))
        #expect(Color.backgroundBottom == Color(hex: 0x15151D))
    }
}
