import SwiftUI

@main
struct TowerDashBricksApp: App {
    @StateObject private var progress = GameProgress()

    init() {
        // Audio session is configured once GameProgress exists (see RootView).
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(progress)
                .preferredColorScheme(.dark)
                .onAppear {
                    AudioService.shared.configure(progress: progress)
                }
        }
    }
}

/// Shows the loading splash, then crossfades into the main menu.
struct RootView: View {
    @State private var showMenu = false

    var body: some View {
        ZStack {
            if showMenu {
                MainMenuView()
                    .transition(.opacity)
            } else {
                LoadingView { withAnimation(.easeInOut(duration: 0.6)) { showMenu = true } }
                    .transition(.opacity)
            }
        }
    }
}
