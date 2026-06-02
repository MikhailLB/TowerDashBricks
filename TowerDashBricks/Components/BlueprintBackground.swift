import SwiftUI

/// "Architect blueprint" backdrop: deep navy wash with fine graph-paper lines,
/// bolder rules every 5 cells, and an optional vignette. Ported from the
/// Flutter `BlueprintBackground` + `_BlueprintPainter`.
struct BlueprintBackground<Content: View>: View {
    var cell: CGFloat = 26
    var vignette: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B2038), Color(hex: 0x0A1828), Color(hex: 0x081320)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Canvas { ctx, size in
                let fine = GraphicsContext.Shading.color(.white.opacity(0.05))
                let bold = GraphicsContext.Shading.color(AppColors.craneYellow.opacity(0.07))

                var i = 0
                var x: CGFloat = 0
                while x <= size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(path, with: i % 5 == 0 ? bold : fine,
                               lineWidth: i % 5 == 0 ? 1.0 : 0.6)
                    x += cell
                    i += 1
                }
                i = 0
                var y: CGFloat = 0
                while y <= size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: i % 5 == 0 ? bold : fine,
                               lineWidth: i % 5 == 0 ? 1.0 : 0.6)
                    y += cell
                    i += 1
                }

                if vignette {
                    let shading = GraphicsContext.Shading.radialGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0.55),
                            .init(color: Color(hex: 0x050C16).opacity(0.6), location: 1.0),
                        ]),
                        center: CGPoint(x: size.width / 2, y: size.height / 2),
                        startRadius: 0,
                        endRadius: max(size.width, size.height) * 0.75
                    )
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
                }
            }
            .ignoresSafeArea()

            content
        }
    }
}
