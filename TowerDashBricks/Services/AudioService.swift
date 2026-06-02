import AVFoundation
import UIKit

enum Sfx {
    case buttonClick
    case blockLand
    case blockFall
    case levelComplete
}

enum Bgm {
    case menu
    case gameplay
}

/// Global audio + haptics. Background music and SFX are loaded from the app
/// bundle if matching files exist; otherwise calls are silent no-ops. (The
/// original game's audio assets are intentionally not bundled here.)
final class AudioService {
    static let shared = AudioService()

    private weak var progress: GameProgress?
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private var currentBgm: Bgm?

    private init() {}

    func configure(progress: GameProgress) {
        self.progress = progress
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: BGM

    private func bgmResource(_ bgm: Bgm) -> String {
        bgm == .menu ? "mainmenumusic" : "gameplaymusic"
    }

    func playBgm(_ bgm: Bgm) {
        guard let progress else { return }
        if currentBgm == bgm, bgmPlayer?.isPlaying == true { return }
        currentBgm = bgm
        guard progress.musicEnabled else { bgmPlayer?.stop(); return }
        guard let url = Self.url(forResource: bgmResource(bgm)) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(progress.musicVolume)
            player.play()
            bgmPlayer = player
        } catch {
            bgmPlayer = nil
        }
    }

    func stopBgm() {
        currentBgm = nil
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    func refreshMusicState() {
        guard let progress else { return }
        if progress.musicEnabled {
            bgmPlayer?.volume = Float(progress.musicVolume)
            if let bgm = currentBgm, bgmPlayer?.isPlaying != true {
                playBgm(bgm)
            }
        } else {
            bgmPlayer?.pause()
        }
    }

    // MARK: SFX

    private func sfxResource(_ sfx: Sfx) -> String {
        switch sfx {
        case .buttonClick, .levelComplete: return "button-click"
        case .blockLand, .blockFall: return "block_fall_sound"
        }
    }

    func playSfx(_ sfx: Sfx) {
        guard let progress, progress.soundEnabled else { return }
        guard let url = Self.url(forResource: sfxResource(sfx)) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(progress.sfxVolume)
            player.play()
            sfxPlayers.append(player)
            sfxPlayers.removeAll { !$0.isPlaying && $0 !== player }
        } catch {
            // No bundled sound — silent.
        }
    }

    // MARK: Haptics

    func vibrate(heavy: Bool = false) {
        guard let progress, progress.vibrationEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: heavy ? .heavy : .medium)
        generator.impactOccurred()
    }

    // MARK: Helpers

    private static func url(forResource name: String) -> URL? {
        for ext in ["mp3", "m4a", "wav", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}
