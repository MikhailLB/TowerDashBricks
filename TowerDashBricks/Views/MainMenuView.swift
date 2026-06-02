import SwiftUI

enum Route: Hashable {
    case levelSelect
    case shop
    case settings
    case game(Int)
    case privacy
    case support
}

struct MainMenuView: View {
    @EnvironmentObject var progress: GameProgress
    @State private var path: [Route] = []
    @State private var showHowTo = false

    private var featured: PuzzleLevel {
        PuzzleLevels.all.first(where: { !progress.isLevelCompleted($0.levelNumber) }) ?? PuzzleLevels.all.last!
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .levelSelect: LevelSelectView(path: $path)
                    case .shop: ShopView()
                    case .settings: SettingsView()
                    case .game(let n): GameView(level: PuzzleLevels.byNumber(n), path: $path)
                    case .privacy: InfoWebView(title: "Privacy Policy", url: "https://towerdashbriicks.com/privacy-policy.html")
                    case .support: InfoWebView(title: "Support", url: "https://towerdashbriicks.com/support.html")
                    }
                }
        }
        .onAppear { AudioService.shared.playBgm(.menu) }
    }

    private var content: some View {
        ZStack {
            BlueprintBackground {
                let total = PuzzleLevels.all.count
                let solved = progress.completedLevels.count
                VStack(spacing: 0) {
                    topBar(solved: solved, total: total)
                    titleBlock
                    Spacer(minLength: 8)
                    FeaturedCard(level: featured, completed: progress.isLevelCompleted(featured.levelNumber))
                        .scaledToFit()
                        .padding(.horizontal, 28)
                    Spacer(minLength: 8)
                    buttons
                }
                .padding(.top, 8)
            }
            if showHowTo {
                HowToPlayView { showHowTo = false }
            }
        }
        .navigationBarHidden(true)
    }

    private func topBar(solved: Int, total: Int) -> some View {
        HStack {
            StatChip(icon: "checkmark.seal.fill", label: "Built", value: "\(solved)/\(total)")
            Spacer()
            StatChip(icon: "circle.circle.fill", label: "Coins", value: "\(progress.coins)")
            CircleAction(icon: "gearshape.fill") {
                AudioService.shared.playSfx(.buttonClick)
                path.append(.settings)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("TOWERDASH")
                .font(AppFont.title(40))
                .foregroundStyle(AppColors.text)
            Text("BRICKS")
                .font(AppFont.title(40))
                .foregroundStyle(AppColors.craneYellow)
                .shadow(color: AppColors.accent.opacity(0.5), radius: 12)
            Text("LAY BRICKS BY LOGIC")
                .font(AppFont.body(11))
                .tracking(3)
                .foregroundStyle(AppColors.craneYellow)
                .padding(.horizontal, 14).padding(.vertical, 4)
                .overlay(Capsule().strokeBorder(AppColors.craneYellow.opacity(0.5)))
        }
        .padding(.top, 22)
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            PixelButton(label: "Play", systemImage: "pencil.and.ruler.fill", width: nil, height: 64, fontSize: 26) {
                AudioService.shared.playSfx(.buttonClick)
                path.append(.levelSelect)
            }
            HStack(spacing: 10) {
                PixelButton(label: "Shop", systemImage: "storefront.fill", width: nil, height: 50, fontSize: 18, color: .secondary) {
                    AudioService.shared.playSfx(.buttonClick)
                    path.append(.shop)
                }
                PixelButton(label: "How to Play", systemImage: "questionmark.circle", width: nil, height: 50, fontSize: 16, color: .secondary) {
                    AudioService.shared.playSfx(.buttonClick)
                    showHowTo = true
                }
            }
            HStack {
                LinkButton(label: "Privacy Policy") { path.append(.privacy) }
                Text("·").foregroundStyle(.white.opacity(0.38))
                LinkButton(label: "Support") { path.append(.support) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}

private struct FeaturedCard: View {
    let level: PuzzleLevel
    let completed: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(completed ? "REPLAY" : "NEXT UP")
                    .font(AppFont.body(10)).tracking(2)
                    .foregroundStyle(AppColors.craneYellow)
                Spacer()
                Text("#\(level.levelNumber)")
                    .font(AppFont.body(12))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.bottom, 12)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: 0x081320))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.12)))
                if completed {
                    BlueprintThumbnail(rowsArt: level.rowsArt).padding(8)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil.and.ruler.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(AppColors.craneYellow.opacity(0.6))
                        Text("LOCKED").font(AppFont.body(10)).tracking(2)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .frame(width: 116, height: 96)
            .padding(.bottom, 12)

            Text(completed ? level.name : "Level \(level.levelNumber)")
                .font(AppFont.title(22))
                .foregroundStyle(AppColors.text)
            Text("\(level.colCount)×\(level.rowCount) grid · \(level.lives) lives")
                .font(AppFont.body(13))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 18, trailing: 20))
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: 0x0E2335).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AppColors.craneYellow.opacity(0.35), lineWidth: 1.5))
                .shadow(color: AppColors.craneYellow.opacity(0.12), radius: 30)
        )
    }
}

struct StatChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(AppColors.craneYellow).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(AppFont.body(10)).tracking(0.8).foregroundStyle(AppColors.textMuted)
                Text(value).font(AppFont.button(15)).foregroundStyle(AppColors.text)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.4)).overlay(Capsule().strokeBorder(AppColors.craneYellow.opacity(0.35), lineWidth: 1.5)))
    }
}

struct CircleAction: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.text).font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(Circle().fill(.black.opacity(0.4)).overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 1.5)))
        }
        .padding(.leading, 10)
    }
}

private struct LinkButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.body(12))
                .foregroundStyle(AppColors.textMuted)
                .underline()
        }
        .padding(.horizontal, 10).padding(.vertical, 12)
    }
}
