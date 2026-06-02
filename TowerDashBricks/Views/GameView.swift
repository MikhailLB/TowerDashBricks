import SwiftUI

/// Hosts a single Blueprint (nonogram) puzzle. Ported from `GameScreen`.
struct GameView: View {
    let level: PuzzleLevel
    @Binding var path: [Route]
    @EnvironmentObject var progress: GameProgress
    @Environment(\.dismiss) private var dismiss

    @StateObject private var controller: NonogramController
    @State private var brickSkin: Int = 1
    @State private var rewarded = false
    @State private var usedGoldRush = false
    @State private var dragBlocked = false
    @State private var showTutorial = false

    init(level: PuzzleLevel, path: Binding<[Route]>) {
        self.level = level
        self._path = path
        self._controller = StateObject(wrappedValue: NonogramController(level: level))
    }

    var body: some View {
        ZStack {
            BlueprintBackground {
                VStack(spacing: 0) {
                    TopBar(level: level, controller: controller,
                           hintsAvailable: progress.hintBoosts,
                           onPause: onPause, onHint: onUseHint)
                    BlueprintGrid(
                        controller: controller,
                        brickSkin: brickSkin,
                        onCellTap: onCellTap,
                        onCellDrag: onCellDrag,
                        onDragStart: { dragBlocked = false }
                    )
                    .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    ModeBar(mode: controller.mode) { controller.setMode($0) }
                    Spacer().frame(height: 8)
                }
            }

            switch controller.status {
            case .paused:
                PauseOverlay(onResume: onResume, onExit: onExit)
            case .scrapped:
                ScrappedOverlay(extraLives: progress.extraLifeBoosts,
                                onUseExtraLife: progress.extraLifeBoosts > 0 ? onUseExtraLife : nil,
                                onRestart: onRestart, onExit: onExit)
            case .complete:
                CompleteOverlay(level: level, brickSkin: brickSkin,
                                perfect: controller.hintsUsed == 0,
                                onNext: onExit, onRestart: onRestart)
            case .building:
                EmptyView()
            }

            if showTutorial {
                HowToPlayView { showTutorial = false; progress.setTutorialSeen() }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            brickSkin = pickSkin()
            usedGoldRush = progress.doubleCoinsBoosts > 0
            showTutorial = !progress.tutorialSeen
            AudioService.shared.playBgm(.gameplay)
        }
    }

    private func pickSkin() -> Int {
        let owned = progress.ownedSkins
        if owned.isEmpty { return 1 }
        let selected = progress.selectedSkin
        if selected != 0, owned.contains(selected) { return selected }
        return owned.randomElement() ?? 1
    }

    private func onCellTap(_ r: Int, _ c: Int) {
        switch controller.handleTap(r, c) {
        case .placed:
            AudioService.shared.playSfx(.blockLand)
        case .mistake, .scrappedRound:
            AudioService.shared.playSfx(.buttonClick)
            AudioService.shared.vibrate(heavy: true)
        case .completedRound:
            onComplete()
        case .marked, .removed:
            AudioService.shared.playSfx(.buttonClick)
        case .ignored:
            break
        }
    }

    private func onCellDrag(_ r: Int, _ c: Int) {
        if dragBlocked { return }
        switch controller.dragPaint(r, c) {
        case .mistake, .scrappedRound:
            dragBlocked = true
            AudioService.shared.playSfx(.buttonClick)
            AudioService.shared.vibrate(heavy: true)
        case .completedRound:
            onComplete()
        default:
            break
        }
    }

    private func onUseHint() {
        guard controller.isInteractive else { return }
        guard progress.consumeHint() else { return }
        AudioService.shared.playSfx(.buttonClick)
        if controller.useHint(), controller.status == .complete {
            onComplete()
        }
    }

    private func onUseExtraLife() {
        guard progress.consumeExtraLife() else { return }
        AudioService.shared.playSfx(.buttonClick)
        controller.reviveWithExtraLife()
    }

    private func onComplete() {
        guard !rewarded else { return }
        rewarded = true
        AudioService.shared.playSfx(.levelComplete)

        progress.completeLevel(level.levelNumber)
        let solved = progress.completedLevels.count
        if solved > progress.highScore { progress.setHighScore(solved) }

        var coins = level.coinReward
        if controller.hintsUsed == 0 { coins += 20 }
        if usedGoldRush, progress.doubleCoinsBoosts > 0 {
            progress.consumeDoubleCoins()
            coins *= 2
        }
        if progress.luckyBoosts > 0 {
            progress.consumeLucky()
            coins += 20
        }
        if coins > 0 { progress.addCoins(coins) }
    }

    private func onPause() { AudioService.shared.playSfx(.buttonClick); controller.pause() }
    private func onResume() { AudioService.shared.playSfx(.buttonClick); controller.resume() }
    private func onRestart() {
        AudioService.shared.playSfx(.buttonClick)
        controller.reset()
        rewarded = false
    }
    private func onExit() { AudioService.shared.playSfx(.buttonClick); dismiss() }
}

// MARK: - Top bar

private struct TopBar: View {
    let level: PuzzleLevel
    @ObservedObject var controller: NonogramController
    let hintsAvailable: Int
    let onPause: () -> Void
    let onHint: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                RoundButton(icon: "pause.fill", action: onPause)
                Spacer()
                VStack(spacing: 0) {
                    Text("WORK ORDER #\(level.levelNumber)")
                        .font(AppFont.body(10)).tracking(2).foregroundStyle(AppColors.craneYellow)
                    Text(level.name).font(AppFont.title(22)).foregroundStyle(AppColors.text)
                }
                Spacer()
                HintButton(count: hintsAvailable, action: hintsAvailable > 0 ? onHint : nil)
            }
            HStack {
                LivesView(left: controller.livesLeft, max: controller.maxLives)
                Spacer()
                BrickProgress(laid: min(controller.bricksLaid, controller.bricksTotal), total: controller.bricksTotal)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 14, bottom: 6, trailing: 14))
    }
}

private struct LivesView: View {
    let left: Int
    let max: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < left ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundStyle(i < left ? AppColors.danger : .white.opacity(0.24))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(panelBg)
    }
}

private struct BrickProgress: View {
    let laid: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill").foregroundStyle(AppColors.craneYellow).font(.system(size: 16))
            Text("\(laid) / \(total)").font(AppFont.button(15)).foregroundStyle(AppColors.text)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(panelBg)
    }
}

private var panelBg: some View {
    RoundedRectangle(cornerRadius: 14)
        .fill(AppColors.panelSolid.opacity(0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.12)))
}

private struct HintButton: View {
    let count: Int
    let action: (() -> Void)?
    var body: some View {
        let enabled = action != nil
        Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(enabled ? AppColors.textDark : .white.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(enabled ? AppColors.craneYellow.opacity(0.85) : AppColors.panelSolid)
                            .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1.5))
                    )
                Text("\(count)")
                    .font(AppFont.body(11)).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Capsule().fill(enabled ? AppColors.danger : .white.opacity(0.24)).overlay(Capsule().strokeBorder(.white, lineWidth: 1)))
                    .offset(x: 4, y: -4)
            }
        }
        .disabled(!enabled)
    }
}

private struct RoundButton: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 24)).foregroundStyle(AppColors.text)
                .frame(width: 48, height: 48)
                .background(Circle().fill(AppColors.panelSolid).shadow(radius: 4))
        }
    }
}

// MARK: - Mode bar

private struct ModeBar: View {
    let mode: EditMode
    let onSelect: (EditMode) -> Void
    var body: some View {
        HStack(spacing: 5) {
            ModeChip(label: "Place Brick", icon: "plus.app.fill", active: mode == .lay) { onSelect(.lay) }
            ModeChip(label: "Mark Gap", icon: "xmark", active: mode == .mark) { onSelect(.mark) }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(AppColors.panelSolid)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(AppColors.cardBorder, lineWidth: 1.5))
        )
        .padding(.horizontal, 24)
    }
}

private struct ModeChip: View {
    let label: String
    let icon: String
    let active: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(AppFont.button(16))
            }
            .foregroundStyle(active ? AppColors.craneYellow : AppColors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(active ? AppColors.craneYellow.opacity(0.18) : .clear)
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(active ? AppColors.craneYellow : .clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Overlays

private struct PauseOverlay: View {
    let onResume: () -> Void
    let onExit: () -> Void
    var body: some View {
        ModalScrim {
            PanelCard(title: "Paused", icon: "pause.circle.fill") {
                PixelButton(label: "Resume", width: nil) { onResume() }
                PixelButton(label: "Main Menu", width: nil, color: .secondary) { onExit() }
            }
        }
    }
}

private struct ScrappedOverlay: View {
    let extraLives: Int
    let onUseExtraLife: (() -> Void)?
    let onRestart: () -> Void
    let onExit: () -> Void
    var body: some View {
        ModalScrim {
            PanelCard(title: "Blueprint Failed", icon: "exclamationmark.triangle.fill") {
                Text("Too many mistakes! The blueprint was scrapped.")
                    .font(AppFont.body(14)).foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                if let onUseExtraLife {
                    PixelButton(label: "Extra Life (x\(extraLives))", systemImage: "shield.fill", width: nil, fontSize: 16) { onUseExtraLife() }
                }
                PixelButton(label: "Restart", width: nil) { onRestart() }
                PixelButton(label: "Main Menu", width: nil, color: .secondary) { onExit() }
            }
        }
    }
}

private struct CompleteOverlay: View {
    let level: PuzzleLevel
    let brickSkin: Int
    let perfect: Bool
    let onNext: () -> Void
    let onRestart: () -> Void

    var body: some View {
        let isLast = level.levelNumber >= PuzzleLevels.all.count
        ModalScrim {
            PanelCard(title: "Complete!", icon: "checkmark.seal.fill") {
                BuiltPreview(level: level, brickSkin: brickSkin)
                Text(level.name).font(AppFont.button(18)).foregroundStyle(AppColors.text)
                HStack(spacing: 8) {
                    Image(systemName: "circle.circle.fill").foregroundStyle(AppColors.craneYellow).font(.system(size: 22))
                    Text("+\(level.coinReward)\(perfect ? " +20" : "") coins")
                        .font(AppFont.score(20)).foregroundStyle(AppColors.craneYellow)
                }
                .padding(.horizontal, 18).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.craneYellow.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppColors.craneYellow, lineWidth: 1.5)))
                if perfect {
                    Text("Perfect — no hints used!").font(AppFont.body(12)).foregroundStyle(AppColors.success)
                }
                if !isLast {
                    PixelButton(label: "Next Level", width: nil) { onNext() }
                }
                PixelButton(label: "Replay", width: nil, color: .secondary) { onRestart() }
            }
        }
    }
}

private struct BuiltPreview: View {
    let level: PuzzleLevel
    let brickSkin: Int
    var body: some View {
        let maxSize: CGFloat = 150
        let cell = maxSize / CGFloat(max(level.rowCount, level.colCount))
        VStack(spacing: 0) {
            ForEach(0..<level.rowCount, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<level.colCount, id: \.self) { c in
                        Group {
                            if level.solutionAt(r, c) {
                                BrickTile(skin: brickSkin)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: cell, height: cell)
                    }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.card).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppColors.craneYellow.opacity(0.4))))
    }
}

private struct ModalScrim<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            ScrollView { content }
        }
    }
}

private struct PanelCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 36)).foregroundStyle(AppColors.craneYellow)
            Text(title).font(AppFont.title(28)).foregroundStyle(AppColors.text)
            content
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 28, trailing: 24))
        .background(
            RoundedRectangle(cornerRadius: 24).fill(AppColors.panelSolid)
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(AppColors.craneYellow.opacity(0.2), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.5), radius: 32)
        )
        .padding(.horizontal, 28).padding(.vertical, 24)
    }
}
