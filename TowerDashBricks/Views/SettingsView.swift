import SwiftUI

/// Audio & haptics preferences. Ported from `SettingsScreen`.
struct SettingsView: View {
    @EnvironmentObject var progress: GameProgress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0A1520), Color(hex: 0x1A2D42), Color(hex: 0x0D1B2A)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel("Sound").padding(.bottom, 10)
                        ToggleTile(icon: "music.note", iconColor: AppColors.craneYellow,
                                   title: "Music", subtitle: "Site soundtrack in menus and on the job",
                                   value: Binding(get: { progress.musicEnabled }, set: {
                                       AudioService.shared.playSfx(.buttonClick)
                                       progress.musicEnabled = $0
                                       AudioService.shared.refreshMusicState()
                                   }))
                        SliderTile(icon: "speaker.wave.2.fill", iconColor: AppColors.craneYellow,
                                   title: "Music Volume", enabled: progress.musicEnabled,
                                   value: Binding(get: { progress.musicVolume }, set: {
                                       progress.musicVolume = $0
                                       AudioService.shared.refreshMusicState()
                                   })).padding(.top, 6)

                        ToggleTile(icon: "waveform", iconColor: AppColors.accent,
                                   title: "Sound Effects", subtitle: "Brick clinks, thuds and button taps",
                                   value: Binding(get: { progress.soundEnabled }, set: {
                                       progress.soundEnabled = $0
                                       if $0 { AudioService.shared.playSfx(.buttonClick) }
                                   })).padding(.top, 14)
                        SliderTile(icon: "speaker.wave.2.fill", iconColor: AppColors.accent,
                                   title: "SFX Volume", enabled: progress.soundEnabled,
                                   value: $progress.sfxVolume).padding(.top, 6)

                        SectionLabel("Haptics").padding(.top, 20).padding(.bottom, 10)
                        ToggleTile(icon: "iphone.radiowaves.left.and.right", iconColor: AppColors.success,
                                   title: "Vibration", subtitle: "Buzz when bricks land or a slip happens",
                                   value: Binding(get: { progress.vibrationEnabled }, set: {
                                       progress.vibrationEnabled = $0
                                       if $0 { AudioService.shared.vibrate() }
                                   }))
                    }
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
                }
                PixelButton(label: "Done", width: nil, height: 58, fontSize: 20) {
                    AudioService.shared.playSfx(.buttonClick); dismiss()
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton { AudioService.shared.playSfx(.buttonClick); dismiss() }
            VStack(alignment: .leading, spacing: 0) {
                Text("SITE OFFICE").font(AppFont.body(10)).tracking(3).foregroundStyle(AppColors.craneYellow)
                Text("Settings").font(AppFont.title(26)).foregroundStyle(AppColors.text)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(AppColors.craneYellow).frame(width: 3, height: 18)
            Text(text.uppercased()).font(AppFont.button(12)).tracking(2).foregroundStyle(AppColors.craneYellow)
        }
    }
}

private struct ToggleTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var value: Bool
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(iconColor)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 10).fill(iconColor.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.button(16)).foregroundStyle(AppColors.text)
                Text(subtitle).font(AppFont.body(12)).foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Toggle("", isOn: $value).labelsHidden().tint(iconColor)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(value ? iconColor.opacity(0.3) : .white.opacity(0.06), lineWidth: 1.5))
        )
    }
}

private struct SliderTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let enabled: Bool
    @Binding var value: Double
    var body: some View {
        let activeColor = enabled ? iconColor : Color.white.opacity(0.24)
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(activeColor)
            Text(title).font(AppFont.body(13)).foregroundStyle(enabled ? AppColors.textMuted : .white.opacity(0.24))
                .frame(width: 90, alignment: .leading)
            Slider(value: $value, in: 0...1).tint(activeColor).disabled(!enabled)
            Text("\(Int((value * 100).rounded()))").font(AppFont.body(13))
                .foregroundStyle(enabled ? AppColors.text : .white.opacity(0.24))
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }
}
