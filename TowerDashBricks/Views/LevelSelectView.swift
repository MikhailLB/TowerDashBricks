import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var progress: GameProgress
    @Binding var path: [Route]
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let solved = progress.completedLevels.count
        let total = PuzzleLevels.all.count

        BlueprintBackground {
            VStack(spacing: 0) {
                header
                progressBar(solved: solved, total: total).padding(.horizontal, 16).padding(.top, 10)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(PuzzleLevels.all) { level in
                            let unlocked = progress.isLevelUnlocked(level.levelNumber)
                            let completed = progress.isLevelCompleted(level.levelNumber)
                            LevelCard(level: level, unlocked: unlocked, completed: completed) {
                                guard unlocked else { return }
                                AudioService.shared.playSfx(.buttonClick)
                                path.append(.game(level.levelNumber))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { AudioService.shared.playBgm(.menu) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BackButton { AudioService.shared.playSfx(.buttonClick); dismiss() }
            VStack(alignment: .leading, spacing: 0) {
                Text("BLUEPRINT ARCHIVE").font(AppFont.body(11)).tracking(3).foregroundStyle(AppColors.craneYellow)
                Text("Choose a Job").font(AppFont.title(26)).foregroundStyle(AppColors.text)
            }
            Spacer()
            CoinPill(coins: progress.coins)
        }
        .padding(.horizontal, 16).padding(.top, 14)
    }

    private func progressBar(solved: Int, total: Int) -> some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(AppColors.craneYellow)
                        .frame(width: total == 0 ? 0 : geo.size.width * CGFloat(solved) / CGFloat(total))
                }
            }
            .frame(height: 6)
            Text("\(solved)/\(total)").font(AppFont.button(13)).foregroundStyle(AppColors.craneYellow)
        }
    }
}

private struct LevelCard: View {
    let level: PuzzleLevel
    let unlocked: Bool
    let completed: Bool
    let onTap: () -> Void

    private var borderColor: Color {
        completed ? AppColors.craneYellow : (unlocked ? AppColors.cardBorder : .white.opacity(0.12))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LVL \(level.levelNumber)").font(AppFont.body(10)).tracking(1.5)
                        .foregroundStyle(unlocked ? AppColors.craneYellow : .white.opacity(0.3))
                    Spacer()
                    Image(systemName: statusIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(statusColor)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x081320))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.1)))
                    if completed {
                        BlueprintThumbnail(rowsArt: level.rowsArt).padding(8)
                    } else {
                        Image(systemName: unlocked ? "square.grid.3x3.fill" : "lock.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(unlocked ? AppColors.craneYellow.opacity(0.5) : .white.opacity(0.24))
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 96)

                Text(completed ? level.name : (unlocked ? "Sealed Blueprint" : "Locked"))
                    .font(AppFont.button(13))
                    .foregroundStyle(unlocked ? AppColors.text : .white.opacity(0.3))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    MiniStat(icon: "squareshape.split.3x3", label: "\(level.colCount)×\(level.rowCount)", color: unlocked ? AppColors.textMuted : .white.opacity(0.24))
                    MiniStat(icon: "heart.fill", label: "\(level.lives)", color: unlocked ? AppColors.textMuted : .white.opacity(0.24))
                    Spacer()
                    Image(systemName: "circle.circle.fill").font(.system(size: 12))
                        .foregroundStyle(unlocked ? AppColors.craneYellow : .white.opacity(0.24))
                    Text("\(level.coinReward)").font(AppFont.body(11))
                        .foregroundStyle(unlocked ? AppColors.craneYellow : .white.opacity(0.24))
                }
            }
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0x0E2335).opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(borderColor, lineWidth: 1.5))
                    .shadow(color: completed ? AppColors.craneYellow.opacity(0.18) : .clear, radius: 12)
            )
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private var statusIcon: String {
        if !unlocked { return "lock.fill" }
        if completed { return "checkmark.circle.fill" }
        return "play.circle.fill"
    }
    private var statusColor: Color {
        if !unlocked { return .white.opacity(0.3) }
        if completed { return AppColors.craneYellow }
        return AppColors.text.opacity(0.7)
    }
}

private struct MiniStat: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(label).font(AppFont.body(11)).foregroundStyle(color)
        }
    }
}

struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.text)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.black.opacity(0.35)).overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1.5)))
        }
    }
}

struct CoinPill: View {
    let coins: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.circle.fill").foregroundStyle(AppColors.craneYellow).font(.system(size: 20))
            Text("\(coins)").font(AppFont.button(16)).foregroundStyle(AppColors.text)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.35)).overlay(Capsule().strokeBorder(AppColors.craneYellow.opacity(0.3), lineWidth: 1.5)))
    }
}
