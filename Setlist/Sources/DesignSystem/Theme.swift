import SwiftUI

/// Visual language straight from the design spec: near-black background, cards one
/// step up, a single loud accent for interactive/completed states, no gradients,
/// 16pt corner radius, condensed-heavy-italic numerals.
enum Theme {
    static let background = Color(hex: 0x0D0D0F)
    static let card = Color(hex: 0x1A1A1E)
    static let cardInset = Color(hex: 0x10_10_12)
    static let raised = Color.white.opacity(0.06)
    static let raisedStrong = Color.white.opacity(0.08)
    static let hairline = Color.white.opacity(0.06)
    static let hairlineStrong = Color.white.opacity(0.08)

    static var accent: Color { SettingsStore.shared.accent.color }
    static let onAccent = Color(hex: 0x0D0D0F)

    static let splitPull = Color(hex: 0x7B_B8_FF)
    static let splitLegs = Color(hex: 0xC0_8B_FF)
    static let splitOther = Color.white.opacity(0.4)
    static let negative = Color(hex: 0xFF_7A_7A)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.45)
    static let textTertiary = Color.white.opacity(0.35)
    static let textGhost = Color.white.opacity(0.3)

    static let radiusLarge: CGFloat = 16
    static let radiusMedium: CGFloat = 12
    static let radiusSmall: CGFloat = 10

    static let tabBarHeight: CGFloat = 84
    static let miniBarHeight: CGFloat = 58
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    /// Approximates the design's "Barlow Condensed, heavy weight, italic" numerals
    /// and headings using SF Pro's condensed width so the app needs no bundled font
    /// files. Drop in a real "BarlowCondensed-ExtraBoldItalic" custom font here for
    /// an exact match to the mockup.
    static func numeral(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed).italic()
    }
}
