import SwiftUI

/// Renders a puzzle solution as a small monochrome silhouette — used on the
/// level cards and menu previews. Ported from the Flutter `BlueprintThumbnail`.
struct BlueprintThumbnail: View {
    let rowsArt: [String]
    var brickColor: Color = AppColors.craneYellow
    var locked: Bool = false

    var body: some View {
        Canvas { ctx, size in
            guard !rowsArt.isEmpty else { return }
            let rows = rowsArt.count
            let cols = rowsArt.first?.count ?? 0
            guard cols > 0 else { return }
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            let gridW = cell * CGFloat(cols)
            let gridH = cell * CGFloat(rows)
            let ox = (size.width - gridW) / 2
            let oy = (size.height - gridH) / 2

            let fill = GraphicsContext.Shading.color(locked ? Color.white.opacity(0.15) : brickColor)
            let gap = GraphicsContext.Shading.color(.white.opacity(0.05))

            let chars = rowsArt.map { Array($0) }
            for r in 0..<rows {
                for c in 0..<cols {
                    let rect = CGRect(
                        x: ox + CGFloat(c) * cell + 0.5,
                        y: oy + CGFloat(r) * cell + 0.5,
                        width: cell - 1,
                        height: cell - 1
                    )
                    ctx.fill(Path(rect), with: chars[r][c] == "#" ? fill : gap)
                }
            }
        }
    }
}
