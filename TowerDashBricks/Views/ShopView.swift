import SwiftUI

/// Forge Yard shop — Brick Skins and Power-Ups tabs. Ported from `ShopScreen`.
struct ShopView: View {
    @EnvironmentObject var progress: GameProgress
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var snack: String?

    private let skinPrices: [Int: Int] = [1: 10, 2: 100, 3: 500]
    private let firstComingSoonSkin = 4
    private let hintPrice = 35
    private let extraLifePrice = 60
    private let goldRushPrice = 80
    private let foremanLuckPrice = 30

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("", selection: $tab) {
                Text("Brick Skins").tag(0)
                Text("Power-Ups").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(AppColors.concrete)

            if tab == 0 { skinsTab } else { powerUpsTab }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) { snackView }
    }

    private var header: some View {
        HStack {
            BackButton { AudioService.shared.playSfx(.buttonClick); dismiss() }
            VStack(alignment: .leading, spacing: 0) {
                Text("FORGE YARD").font(AppFont.body(10)).tracking(3).foregroundStyle(AppColors.craneYellow)
                Text("Shop").font(AppFont.title(26)).foregroundStyle(AppColors.text)
            }
            .padding(.leading, 8)
            Spacer()
            CoinPill(coins: progress.coins)
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
        .background(AppColors.concrete.ignoresSafeArea(edges: .top))
    }

    // MARK: Skins

    private var skinsTab: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(1...6, id: \.self) { skin in
                    SkinTile(
                        skin: skin,
                        owned: progress.ownedSkins.contains(skin),
                        selected: progress.selectedSkin == skin,
                        price: skinPrices[skin],
                        comingSoon: skin >= firstComingSoonSkin
                    ) { buySkin(skin) }
                }
            }
            .padding(16)

            randomToggle.padding(.horizontal, 16).padding(.bottom, 24)
        }
    }

    private var randomToggle: some View {
        let isRandom = progress.selectedSkin == 0
        return Button {
            AudioService.shared.playSfx(.buttonClick)
            progress.setSelectedSkin(0)
        } label: {
            HStack {
                Image(systemName: "shuffle")
                    .foregroundStyle(isRandom ? AppColors.craneYellow : AppColors.textMuted)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill((isRandom ? AppColors.craneYellow : AppColors.textMuted).opacity(0.15)))
                VStack(alignment: .leading) {
                    Text("Random Rotation").font(AppFont.button(16))
                        .foregroundStyle(isRandom ? AppColors.craneYellow : AppColors.text)
                    Text("Cycle through all owned skins each game")
                        .font(AppFont.body(12)).foregroundStyle(AppColors.textMuted)
                }
                Spacer()
                if isRandom {
                    Text("ACTIVE").font(AppFont.body(11)).tracking(1).foregroundStyle(AppColors.textDark)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.craneYellow))
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isRandom ? AppColors.craneYellow.opacity(0.15) : AppColors.panelSolid)
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isRandom ? AppColors.craneYellow : AppColors.cardBorder, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private func buySkin(_ skin: Int) {
        AudioService.shared.playSfx(.buttonClick)
        if skin >= firstComingSoonSkin { showSnack("Coming soon!"); return }
        if progress.ownedSkins.contains(skin) { progress.setSelectedSkin(skin); return }
        guard let price = skinPrices[skin] else { return }
        guard progress.spendCoins(price) else { showSnack("Not enough coins"); return }
        progress.unlockSkin(skin)
        progress.setSelectedSkin(0)
    }

    // MARK: Power-ups

    private var powerUpsTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                BoostTile(icon: "lightbulb.fill", title: "Blueprint Hint",
                          subtitle: "Reveals one correct brick — no mistake counted.",
                          price: hintPrice, owned: progress.hintBoosts, color: AppColors.craneYellow) {
                    buyBoost(hintPrice) { progress.grantHint($0) }
                }
                BoostTile(icon: "shield.fill", title: "Reinforcement",
                          subtitle: "Revives a scrapped blueprint with one extra life.",
                          price: extraLifePrice, owned: progress.extraLifeBoosts, color: AppColors.danger) {
                    buyBoost(extraLifePrice) { progress.grantExtraLife($0) }
                }
                BoostTile(icon: "creditcard.fill", title: "Gold Rush",
                          subtitle: "Doubles coin rewards for your next puzzle.",
                          price: goldRushPrice, owned: progress.doubleCoinsBoosts, color: AppColors.craneYellow) {
                    buyBoost(goldRushPrice) { progress.grantDoubleCoins($0) }
                }
                BoostTile(icon: "dice.fill", title: "Foreman's Luck",
                          subtitle: "+20 bonus coins when you complete a puzzle.",
                          price: foremanLuckPrice, owned: progress.luckyBoosts, color: AppColors.success) {
                    buyBoost(foremanLuckPrice) { progress.grantLucky($0) }
                }
            }
            .padding(16)
        }
    }

    private func buyBoost(_ price: Int, _ grant: (Int) -> Void) {
        AudioService.shared.playSfx(.buttonClick)
        guard progress.spendCoins(price) else { showSnack("Not enough coins"); return }
        grant(1)
    }

    // MARK: Snack

    private func showSnack(_ text: String) {
        snack = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if snack == text { snack = nil }
        }
    }

    @ViewBuilder private var snackView: some View {
        if let snack {
            Text(snack)
                .font(AppFont.body())
                .foregroundStyle(AppColors.text)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(AppColors.panelSolid))
                .padding(.bottom, 30)
                .transition(.opacity)
        }
    }
}

private struct SkinTile: View {
    let skin: Int
    let owned: Bool
    let selected: Bool
    let price: Int?
    let comingSoon: Bool
    let onTap: () -> Void

    private var borderColor: Color {
        selected ? AppColors.craneYellow : (owned ? AppColors.cardBorder : .white.opacity(0.12))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    BrickTile(skin: skin, cornerRadius: 8)
                        .opacity(comingSoon ? 0.25 : 1)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 4, trailing: 10))
                        .frame(height: 90)
                    if comingSoon {
                        Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                            .padding(5).background(Circle().fill(.black.opacity(0.7)))
                            .padding(8)
                    }
                }
                bottomLabel
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(bottomColor)
            }
            .background(RoundedRectangle(cornerRadius: 18).fill(AppColors.panelSolid))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(borderColor, lineWidth: 2))
            .shadow(color: selected ? AppColors.craneYellow.opacity(0.25) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private var bottomColor: Color {
        if selected { return AppColors.craneYellow.opacity(0.25) }
        if owned { return AppColors.cardBorder.opacity(0.3) }
        if comingSoon { return .white.opacity(0.04) }
        return AppColors.brickRed.opacity(0.15)
    }

    @ViewBuilder private var bottomLabel: some View {
        if comingSoon {
            Text("Coming Soon").font(AppFont.body(11)).foregroundStyle(.white.opacity(0.38))
        } else if selected {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(AppColors.craneYellow)
                Text("EQUIPPED").font(AppFont.body(11)).tracking(1).foregroundStyle(AppColors.craneYellow)
            }
        } else if owned {
            Text("Tap to equip").font(AppFont.body(11)).foregroundStyle(AppColors.textMuted)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle.circle.fill").font(.system(size: 14)).foregroundStyle(AppColors.craneYellow)
                Text("\(price ?? 0)").font(AppFont.button(14)).foregroundStyle(AppColors.craneYellow)
            }
        }
    }
}

private struct BoostTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let price: Int
    let owned: Int
    let color: Color
    let onBuy: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(color).frame(width: 4, height: 80)
                .clipShape(RoundedCorners(radius: 16, corners: [.topLeft, .bottomLeft]))
            Image(systemName: icon).font(.system(size: 24)).foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)))
                .padding(.leading, 14).padding(.trailing, 12)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title).font(AppFont.button(15)).foregroundStyle(AppColors.text)
                    if owned > 0 {
                        Text("×\(owned)").font(AppFont.body(11)).foregroundStyle(color)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(0.2)).overlay(Capsule().strokeBorder(color.opacity(0.6))))
                    }
                }
                Text(subtitle).font(AppFont.body(12)).foregroundStyle(AppColors.textMuted)
            }
            .padding(.vertical, 14)
            Spacer(minLength: 10)
            PixelButton(label: "\(price)", width: 82, height: 42, fontSize: 15) { onBuy() }
                .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16).fill(AppColors.panelSolid)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(owned > 0 ? color.opacity(0.4) : AppColors.cardBorder.opacity(0.5), lineWidth: 1.5))
        )
    }
}

/// Helper to round specific corners.
struct RoundedCorners: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
