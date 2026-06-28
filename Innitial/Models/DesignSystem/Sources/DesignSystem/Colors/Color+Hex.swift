import SwiftUI

public extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0x8000FF)`.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
