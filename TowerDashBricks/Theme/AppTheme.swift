import SwiftUI

/// Central palette ported from the Flutter `AppColors`. Same dark-industrial,
/// construction-blueprint look (white iOS branch).
enum AppColors {
    static let background = Color(hex: 0x0D1B2A)
    static let concrete = Color(hex: 0x1E2D3D)

    static let brickRed = Color(hex: 0x8B3A2F)
    static let rust = Color(hex: 0xB04A1E)

    static let craneYellow = Color(hex: 0xF5A623)
    static let accent = Color(hex: 0xD4541A)
    static let accentDeep = Color(hex: 0x9C3A0E)

    static let panelSolid = Color(hex: 0x1E2D3D)
    static let panelLight = Color(hex: 0x2A3D52)
    static let card = Color(hex: 0x162230)
    static let cardBorder = Color(hex: 0x2D4A62)

    static let text = Color(hex: 0xF5F0E8)
    static let textMuted = Color(hex: 0x8A9BAB)
    static let textDark = Color(hex: 0x0D1B2A)

    static let danger = Color(hex: 0xE84545)
    static let success = Color(hex: 0x2ECC71)

    static let menuBgTop = Color(hex: 0x0A1520)
    static let menuBgBottom = Color(hex: 0x1A2D42)

    static let btnSecTop = Color(hex: 0x2D4A62)
    static let btnSecBottom = Color(hex: 0x162230)
    static let btnSecBorder = Color(hex: 0x4A7090)
}

/// Roboto Slab is substituted with the system serif design so the app needs
/// no bundled font files (the original relied on google_fonts).
enum AppFont {
    static func title(_ size: CGFloat = 38) -> Font {
        .system(size: size, weight: .heavy, design: .serif)
    }
    static func button(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
    static func score(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
