import SwiftUI

/// Full-screen, swipeable tutorial explaining the nonogram rules. Used as a
/// first-run overlay and from the menu's "How to Play". Ported from
/// `HowToPlayOverlay`.
struct HowToPlayView: View {
    let onClose: () -> Void
    @State private var page = 0

    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
        let showSample: Bool
    }

    private let steps: [Step] = [
        Step(icon: "number", title: "Read the Plan",
             body: "The numbers along each row and column are the brick runs — how many bricks sit shoulder-to-shoulder, listed in the order they appear.",
             showSample: true),
        Step(icon: "plus.app.fill", title: "Lay the Bricks",
             body: "Tap a square to set a brick where the plan calls for one. Slide your finger along the grid to lay a whole course in one go.",
             showSample: false),
        Step(icon: "xmark", title: "Flag the Voids",
             body: "Flip to \"Flag Void\" to chalk an X on squares you've ruled out. Flagging is free and never costs you an attempt.",
             showSample: false),
        Step(icon: "heart.fill", title: "Watch Your Attempts",
             body: "Drop a brick in the wrong square and you lose an attempt. Run dry and the site is shut down. Stuck? Tap the bulb for a surveyor's tip.",
             showSample: false),
    ]

    var body: some View {
        let isLast = page == steps.count - 1
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Text("Skip")
                            .font(AppFont.body(15))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(12)
                }

                TabView(selection: $page) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        StepView(step: step).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? AppColors.craneYellow : Color.white.opacity(0.24))
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }
                .padding(.vertical, 8)

                PixelButton(
                    label: isLast ? "Grab a Trowel" : "Next",
                    width: nil,
                    height: 56,
                    fontSize: 20
                ) {
                    if isLast {
                        onClose()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .padding(.top, 18)
            }
        }
    }

    private struct StepView: View {
        let step: Step

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppColors.craneYellow.opacity(0.15))
                        .overlay(Circle().strokeBorder(AppColors.craneYellow, lineWidth: 2))
                        .frame(width: 96, height: 96)
                    Image(systemName: step.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(AppColors.craneYellow)
                }
                .padding(.bottom, 28)

                Text(step.title)
                    .font(AppFont.title(28))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)

                Text(step.body)
                    .font(AppFont.body(16))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)

                if step.showSample {
                    ClueSample().padding(.top, 26)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    /// A tiny worked example: clue "3 1" → filled pattern ███ ░ █.
    private struct ClueSample: View {
        private let pattern = [true, true, true, false, true]
        var body: some View {
            HStack(spacing: 12) {
                Text("3  1")
                    .font(AppFont.button(18))
                    .foregroundStyle(AppColors.craneYellow)
                Image(systemName: "arrow.right")
                    .foregroundStyle(AppColors.textMuted)
                HStack(spacing: 3) {
                    ForEach(0..<pattern.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(pattern[i] ? AppColors.craneYellow : AppColors.card)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.24)))
                            .frame(width: 26, height: 26)
                    }
                }
            }
        }
    }
}
