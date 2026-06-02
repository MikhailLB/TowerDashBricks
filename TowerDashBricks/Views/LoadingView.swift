import SwiftUI
import AVKit

/// Splash screen that plays a looping promo video and shows a 4-state loading
/// bar while the game warms up. Reuses the only bundled assets (the loading
/// videos and bar frames). Ported from `LoadingScreen`.
struct LoadingView: View {
    let onFinished: () -> Void

    @State private var showBar = false
    @State private var barState = 1
    @State private var finished = false

    private let minDuration: Double = 6.0
    private let barDuration: Double = 4.5

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height >= geo.size.width
            ZStack {
                Color.black.ignoresSafeArea()

                LoopingVideoView(resourceName: isPortrait ? "9x16_loading_screen" : "16x9_loading_screen")
                    .ignoresSafeArea()

                if showBar {
                    VStack {
                        Spacer()
                        LoadingBar(state: barState, isPortrait: isPortrait, screen: geo.size)
                            .padding(.bottom, 12)
                    }
                }
            }
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        // Reveal the bar shortly after start.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            showBar = true
            animateBar()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + minDuration + 0.3) {
            guard !finished else { return }
            finished = true
            onFinished()
        }
    }

    private func animateBar() {
        // Step through the four bar frames across `barDuration`.
        let steps = 4
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + barDuration * Double(i) / Double(steps)) {
                barState = i
            }
        }
    }
}

private struct LoadingBar: View {
    let state: Int
    let isPortrait: Bool
    let screen: CGSize

    var body: some View {
        let width = isPortrait ? screen.width * 0.7 : screen.height * 0.4
        Group {
            if let image = ResourceImage.load("loading_bar_0\(state)") ?? ResourceImage.load("tdb_bar_\(state)") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback progress bar if the bundled frames are missing.
                ProgressView(value: Double(state), total: 4)
                    .tint(AppColors.craneYellow)
                    .padding(.horizontal)
            }
        }
        .frame(width: width)
    }
}

/// Loads an image file (e.g. webp) from the app bundle.
enum ResourceImage {
    static func load(_ name: String) -> UIImage? {
        if let img = UIImage(named: name) { return img }
        for ext in ["webp", "png", "jpg", "jpeg"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                return img
            }
        }
        return nil
    }
}

/// Plays a bundled video on a loop, scaled to cover the view.
struct LoopingVideoView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(resourceName: resourceName)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.update(resourceName: resourceName)
    }

    final class PlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var looper: Any?
        private var currentName: String = ""

        init(resourceName: String) {
            super.init(frame: .zero)
            backgroundColor = .black
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)
            update(resourceName: resourceName)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func update(resourceName: String) {
            guard resourceName != currentName else { return }
            currentName = resourceName
            guard let url = Self.videoURL(resourceName) else { return }
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            queuePlayer.isMuted = true
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            playerLayer.player = queuePlayer
            queuePlayer.play()
        }

        private static func videoURL(_ name: String) -> URL? {
            for ext in ["mp4", "mov", "m4v"] {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
            return nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
