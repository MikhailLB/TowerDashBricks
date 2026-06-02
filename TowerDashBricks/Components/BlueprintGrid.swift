import SwiftUI

/// Renders the blueprint grid with row/column clues and forwards taps & drags.
/// Sizes itself to the available space and keeps cells square. Ported from the
/// Flutter `BlueprintGrid`.
struct BlueprintGrid: View {
    @ObservedObject var controller: NonogramController
    let brickSkin: Int
    let onCellTap: (Int, Int) -> Void
    let onCellDrag: (Int, Int) -> Void
    let onDragStart: () -> Void

    @State private var lastDragRow: Int?
    @State private var lastDragCol: Int?
    @State private var dragging = false

    private let frame: CGFloat = 2

    private var maxRowClueLen: Int {
        controller.level.rowClues.map { $0.count }.max() ?? 1
    }
    private var maxColClueLen: Int {
        controller.level.colClues.map { $0.count }.max() ?? 1
    }

    var body: some View {
        let rows = controller.rows
        let cols = controller.cols
        let leftUnits = CGFloat(maxRowClueLen) + 0.5
        let topUnits = CGFloat(maxColClueLen) + 0.5

        GeometryReader { geo in
            let cell = min(
                (geo.size.width - frame * 2) / (CGFloat(cols) + leftUnits),
                (geo.size.height - frame * 2) / (CGFloat(rows) + topUnits)
            )
            let gridW = cell * CGFloat(cols)
            let gridH = cell * CGFloat(rows)
            let leftGutter = cell * leftUnits
            let topGutter = cell * topUnits

            VStack(alignment: .leading, spacing: 0) {
                // Top: corner spacer + column clues
                HStack(alignment: .bottom, spacing: 0) {
                    Color.clear.frame(width: leftGutter + frame, height: topGutter)
                    ForEach(0..<cols, id: \.self) { c in
                        ColumnClue(
                            clues: controller.level.colClues[c],
                            size: cell,
                            height: topGutter,
                            emphasized: (c + 1) % 5 == 0,
                            dim: controller.colSatisfied(c)
                        )
                    }
                }

                // Body: row clues + cells
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(0..<rows, id: \.self) { r in
                            RowClue(
                                clues: controller.level.rowClues[r],
                                size: cell,
                                width: leftGutter,
                                emphasized: (r + 1) % 5 == 0,
                                dim: controller.rowSatisfied(r)
                            )
                        }
                    }
                    .frame(width: leftGutter, height: gridH + frame * 2)
                    .padding(.top, frame)

                    cellGrid(cell: cell, gridW: gridW, gridH: gridH, rows: rows, cols: cols)
                }
            }
            .frame(width: leftGutter + gridW + frame * 2,
                   height: topGutter + gridH + frame * 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cellGrid(cell: CGFloat, gridW: CGFloat, gridH: CGFloat, rows: Int, cols: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { c in
                        CellView(
                            mark: controller.cellAt(r, c),
                            brickSkin: brickSkin,
                            size: cell,
                            flashing: controller.flashRow == r && controller.flashCol == c,
                            rightHeavy: (c + 1) % 5 == 0 && c != cols - 1,
                            bottomHeavy: (r + 1) % 5 == 0 && r != rows - 1
                        )
                    }
                }
            }
        }
        .padding(frame)
        .frame(width: gridW + frame * 2, height: gridH + frame * 2)
        .background(AppColors.card)
        .overlay(
            Rectangle().strokeBorder(AppColors.craneYellow.opacity(0.8), lineWidth: frame)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dist = hypot(value.translation.width, value.translation.height)
                    // Only promote to a "paint drag" once the finger moves a bit,
                    // so a plain tap never triggers drag-painting.
                    if !dragging && dist > 10 {
                        dragging = true
                        onDragStart()
                        lastDragRow = nil
                        lastDragCol = nil
                    }
                    guard dragging else { return }
                    let (r, c) = cellIndex(value.location, cell: cell, rows: rows, cols: cols)
                    if lastDragRow == r && lastDragCol == c { return }
                    lastDragRow = r
                    lastDragCol = c
                    onCellDrag(r, c)
                }
                .onEnded { value in
                    if !dragging {
                        let (r, c) = cellIndex(value.location, cell: cell, rows: rows, cols: cols)
                        onCellTap(r, c)
                    }
                    dragging = false
                    lastDragRow = nil
                    lastDragCol = nil
                }
        )
    }

    private func cellIndex(_ local: CGPoint, cell: CGFloat, rows: Int, cols: Int) -> (Int, Int) {
        // Account for the frame padding offset.
        let x = local.x - frame
        let y = local.y - frame
        let c = min(max(0, Int(x / cell)), cols - 1)
        let r = min(max(0, Int(y / cell)), rows - 1)
        return (r, c)
    }
}

// MARK: - Cell

private struct CellView: View {
    let mark: CellMark
    let brickSkin: Int
    let size: CGFloat
    let flashing: Bool
    let rightHeavy: Bool
    let bottomHeavy: Bool

    var body: some View {
        let lineColor = Color.white.opacity(0.10)
        let heavyColor = AppColors.craneYellow.opacity(0.35)

        ZStack {
            Rectangle()
                .fill(backgroundColor)
            content
        }
        .frame(width: size, height: size)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(rightHeavy ? heavyColor : lineColor)
                .frame(width: rightHeavy ? 1.5 : 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(bottomHeavy ? heavyColor : lineColor)
                .frame(height: bottomHeavy ? 1.5 : 0.5)
        }
    }

    private var backgroundColor: Color {
        if flashing { return AppColors.danger.opacity(0.55) }
        if mark == .brick { return .clear }
        return AppColors.card.opacity(0.4)
    }

    @ViewBuilder private var content: some View {
        switch mark {
        case .brick:
            BrickTile(skin: brickSkin)
                .padding(size * 0.04)
        case .cross:
            Image(systemName: "xmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(AppColors.textMuted.opacity(0.75))
        case .empty:
            EmptyView()
        }
    }
}

// MARK: - Clues

private struct RowClue: View {
    let clues: [Int]
    let size: CGFloat
    let width: CGFloat
    let emphasized: Bool
    let dim: Bool

    var body: some View {
        let visible = clues.filter { $0 > 0 }
        HStack(spacing: size * 0.24) {
            if visible.isEmpty {
                ClueNumber(value: 0, size: size, emphasized: emphasized, dim: dim)
            } else {
                ForEach(Array(visible.enumerated()), id: \.offset) { _, n in
                    ClueNumber(value: n, size: size, emphasized: emphasized, dim: dim)
                }
            }
        }
        .frame(width: width, height: size, alignment: .trailing)
        .padding(.trailing, size * 0.2)
    }
}

private struct ColumnClue: View {
    let clues: [Int]
    let size: CGFloat
    let height: CGFloat
    let emphasized: Bool
    let dim: Bool

    var body: some View {
        let visible = clues.filter { $0 > 0 }
        VStack(spacing: size * 0.13) {
            if visible.isEmpty {
                ClueNumber(value: 0, size: size, emphasized: emphasized, dim: dim)
            } else {
                ForEach(Array(visible.enumerated()), id: \.offset) { _, n in
                    ClueNumber(value: n, size: size, emphasized: emphasized, dim: dim)
                }
            }
        }
        .frame(width: size, height: height, alignment: .bottom)
        .padding(.bottom, size * 0.16)
    }
}

private struct ClueNumber: View {
    let value: Int
    let size: CGFloat
    let emphasized: Bool
    let dim: Bool

    var body: some View {
        let base = emphasized ? AppColors.craneYellow : AppColors.text
        Text("\(value)")
            .font(AppFont.button(size * 0.5))
            .foregroundStyle(dim ? base.opacity(0.25) : base)
            .fixedSize()
    }
}
