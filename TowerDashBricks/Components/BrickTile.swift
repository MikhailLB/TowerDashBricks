import SwiftUI

/// Procedurally drawn brick used in place of the original `tdb_brick_0X.webp`
/// assets. Six "skins" map to six colour schemes so the shop's skin system
/// keeps working without any imported art.
struct BrickTile: View {
    let skin: Int
    var cornerRadius: CGFloat = 3

    private struct Palette {
        let top: Color
        let bottom: Color
        let mortar: Color
        let highlight: Color
    }

    private static let palettes: [Palette] = [
        // 1 - classic brick red
        Palette(top: Color(hex: 0xC0533B), bottom: Color(hex: 0x7E2E22),
                mortar: Color(hex: 0x3A1410), highlight: Color(hex: 0xE08763)),
        // 2 - construction yellow
        Palette(top: Color(hex: 0xF5B942), bottom: Color(hex: 0xC07A12),
                mortar: Color(hex: 0x5A3A05), highlight: Color(hex: 0xFFE08A)),
        // 3 - steel blue
        Palette(top: Color(hex: 0x5A86B0), bottom: Color(hex: 0x2D4A62),
                mortar: Color(hex: 0x132838), highlight: Color(hex: 0x9CC2E0)),
        // 4 - emerald
        Palette(top: Color(hex: 0x4FB877), bottom: Color(hex: 0x1F7A45),
                mortar: Color(hex: 0x0C3320), highlight: Color(hex: 0x9CE8B8)),
        // 5 - violet
        Palette(top: Color(hex: 0x9B6BD6), bottom: Color(hex: 0x5C3699),
                mortar: Color(hex: 0x2A1547), highlight: Color(hex: 0xCBA8F0)),
        // 6 - graphite
        Palette(top: Color(hex: 0x6E7B89), bottom: Color(hex: 0x39434E),
                mortar: Color(hex: 0x171C22), highlight: Color(hex: 0xAAB6C2)),
    ]

    private var palette: Palette {
        let idx = max(1, skin) - 1
        return Self.palettes[idx % Self.palettes.count]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let p = palette
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [p.top, p.bottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                // Top highlight band
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [p.highlight.opacity(0.55), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(w * 0.06)
                // Mortar border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(p.mortar.opacity(0.9), lineWidth: max(0.8, w * 0.06))
                // Bottom shadow line for depth
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, p.mortar.opacity(0.35)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: w, height: h)
        }
    }
}
