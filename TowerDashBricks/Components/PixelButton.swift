import SwiftUI

enum PixelButtonColor {
    case primary
    case secondary
    case danger
}

/// Industrial-style game button with gradient, glow and press animation.
/// Ported from the Flutter `PixelButton`.
struct PixelButton: View {
    let label: String
    var systemImage: String?
    var width: CGFloat? = 220
    var height: CGFloat = 60
    var fontSize: CGFloat = 22
    var color: PixelButtonColor = .primary
    var enabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    private struct Scheme {
        let top: Color
        let bottom: Color
        let topPress: Color
        let bottomPress: Color
        let border: Color
        let glow: Color
    }

    private var scheme: Scheme {
        switch color {
        case .primary:
            return Scheme(top: AppColors.craneYellow, bottom: AppColors.accent,
                          topPress: Color(hex: 0xCC8A00), bottomPress: AppColors.accentDeep,
                          border: AppColors.rust.opacity(0.8), glow: AppColors.craneYellow.opacity(0.3))
        case .secondary:
            return Scheme(top: AppColors.btnSecTop, bottom: AppColors.btnSecBottom,
                          topPress: Color(hex: 0x1E3448), bottomPress: Color(hex: 0x0A1520),
                          border: AppColors.btnSecBorder.opacity(0.8), glow: AppColors.btnSecBorder.opacity(0.2))
        case .danger:
            return Scheme(top: Color(hex: 0xE84545), bottom: Color(hex: 0x9C2020),
                          topPress: Color(hex: 0xB03030), bottomPress: Color(hex: 0x6E1515),
                          border: Color(hex: 0xE84545).opacity(0.7), glow: Color(hex: 0xE84545).opacity(0.25))
        }
    }

    var body: some View {
        let s = scheme
        let radius = height * 0.32
        let t: CGFloat = pressed ? 1 : 0

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            lerp(s.top, s.topPress, t),
                            lerp(s.bottom, s.bottomPress, t),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(s.border, lineWidth: 1.5)
                )
                .shadow(color: s.glow, radius: 12 * (1 - t * 0.8))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4 * (1 - t * 0.7))

            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: fontSize * 1.1, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(AppFont.button(fontSize))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.65), radius: 4, x: 0, y: 2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .opacity(enabled ? 1 : 0.4)
        .scaleEffect(pressed ? 0.95 : 1)
        .animation(.easeOut(duration: 0.09), value: pressed)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if enabled { pressed = true } }
                .onEnded { _ in
                    pressed = false
                    if enabled { action() }
                }
        )
    }

    private func lerp(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        let ua = UIColor(a)
        let ub = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        ua.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        ub.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(.sRGB,
                     red: ar + (br - ar) * t,
                     green: ag + (bg - ag) * t,
                     blue: ab + (bb - ab) * t,
                     opacity: aa + (ba - aa) * t)
    }
}
