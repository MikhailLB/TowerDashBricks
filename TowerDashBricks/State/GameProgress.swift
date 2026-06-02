import SwiftUI

/// Player progress + preferences, persisted to `UserDefaults`. Combines the
/// roles of the Dart `StorageService` and `GameProgress`.
final class GameProgress: ObservableObject {
    private let defaults: UserDefaults

    // MARK: Keys
    private enum K {
        static let highScore = "st_high_score"
        static let coins = "st_coins"
        static let ownedSkins = "st_owned_skins"
        static let selectedSkin = "st_selected_skin"
        static let highestUnlockedLevel = "st_highest_unlocked_level"
        static let completedLevels = "st_completed_levels"
        static let tutorialSeen = "st_tutorial_seen"
        static let boostHint = "st_boost_hint"
        static let boostExtraLife = "st_boost_extra_life"
        static let boostDoubleCoins = "st_boost_double_coins"
        static let boostLucky = "st_boost_lucky"
        static let soundEnabled = "st_sound_enabled"
        static let musicEnabled = "st_music_enabled"
        static let vibrationEnabled = "st_vibration_enabled"
        static let musicVolume = "st_music_volume"
        static let sfxVolume = "st_sfx_volume"
    }

    @Published private(set) var coins: Int
    @Published private(set) var highScore: Int
    @Published private(set) var highestUnlockedLevel: Int
    @Published private(set) var completedLevels: Set<Int>
    @Published private(set) var hintBoosts: Int
    @Published private(set) var extraLifeBoosts: Int
    @Published private(set) var doubleCoinsBoosts: Int
    @Published private(set) var luckyBoosts: Int
    @Published private(set) var ownedSkins: [Int]
    @Published private(set) var selectedSkin: Int
    @Published private(set) var tutorialSeen: Bool
    @Published var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: K.soundEnabled) } }
    @Published var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: K.musicEnabled) } }
    @Published var vibrationEnabled: Bool { didSet { defaults.set(vibrationEnabled, forKey: K.vibrationEnabled) } }
    @Published var musicVolume: Double { didSet { defaults.set(musicVolume, forKey: K.musicVolume) } }
    @Published var sfxVolume: Double { didSet { defaults.set(sfxVolume, forKey: K.sfxVolume) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Seed defaults (mirrors StorageService._seedDefaults).
        if defaults.object(forKey: K.ownedSkins) == nil {
            defaults.set(["1"], forKey: K.ownedSkins)
        }
        if defaults.object(forKey: K.selectedSkin) == nil {
            defaults.set(0, forKey: K.selectedSkin)
        }
        if defaults.object(forKey: K.highestUnlockedLevel) == nil {
            defaults.set(1, forKey: K.highestUnlockedLevel)
        }
        if defaults.object(forKey: K.soundEnabled) == nil { defaults.set(true, forKey: K.soundEnabled) }
        if defaults.object(forKey: K.musicEnabled) == nil { defaults.set(true, forKey: K.musicEnabled) }
        if defaults.object(forKey: K.vibrationEnabled) == nil { defaults.set(true, forKey: K.vibrationEnabled) }
        if defaults.object(forKey: K.musicVolume) == nil { defaults.set(0.6, forKey: K.musicVolume) }
        if defaults.object(forKey: K.sfxVolume) == nil { defaults.set(0.8, forKey: K.sfxVolume) }

        coins = defaults.integer(forKey: K.coins)
        highScore = defaults.integer(forKey: K.highScore)
        highestUnlockedLevel = defaults.integer(forKey: K.highestUnlockedLevel)
        let completed = (defaults.stringArray(forKey: K.completedLevels) ?? []).compactMap { Int($0) }
        completedLevels = Set(completed)
        hintBoosts = defaults.integer(forKey: K.boostHint)
        extraLifeBoosts = defaults.integer(forKey: K.boostExtraLife)
        doubleCoinsBoosts = defaults.integer(forKey: K.boostDoubleCoins)
        luckyBoosts = defaults.integer(forKey: K.boostLucky)
        ownedSkins = (defaults.stringArray(forKey: K.ownedSkins) ?? ["1"]).compactMap { Int($0) }.sorted()
        selectedSkin = defaults.integer(forKey: K.selectedSkin)
        tutorialSeen = defaults.bool(forKey: K.tutorialSeen)
        soundEnabled = defaults.bool(forKey: K.soundEnabled)
        musicEnabled = defaults.bool(forKey: K.musicEnabled)
        vibrationEnabled = defaults.bool(forKey: K.vibrationEnabled)
        musicVolume = defaults.double(forKey: K.musicVolume)
        sfxVolume = defaults.double(forKey: K.sfxVolume)
    }

    // MARK: Coins & score

    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        defaults.set(coins, forKey: K.coins)
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        defaults.set(coins, forKey: K.coins)
        return true
    }

    func setHighScore(_ score: Int) {
        guard score > highScore else { return }
        highScore = score
        defaults.set(highScore, forKey: K.highScore)
    }

    // MARK: Levels

    func completeLevel(_ levelNumber: Int) {
        completedLevels.insert(levelNumber)
        defaults.set(completedLevels.map(String.init), forKey: K.completedLevels)
        if levelNumber >= highestUnlockedLevel {
            highestUnlockedLevel = levelNumber + 1
            defaults.set(highestUnlockedLevel, forKey: K.highestUnlockedLevel)
        }
    }

    func isLevelUnlocked(_ levelNumber: Int) -> Bool { levelNumber <= highestUnlockedLevel }
    func isLevelCompleted(_ levelNumber: Int) -> Bool { completedLevels.contains(levelNumber) }

    // MARK: Skins

    func setSelectedSkin(_ skin: Int) {
        selectedSkin = skin
        defaults.set(skin, forKey: K.selectedSkin)
    }

    func setTutorialSeen() {
        guard !tutorialSeen else { return }
        tutorialSeen = true
        defaults.set(true, forKey: K.tutorialSeen)
    }

    func unlockSkin(_ skin: Int) {
        guard !ownedSkins.contains(skin) else { return }
        ownedSkins = (ownedSkins + [skin]).sorted()
        defaults.set(ownedSkins.map(String.init), forKey: K.ownedSkins)
    }

    // MARK: Power-ups

    func grantHint(_ amount: Int) { hintBoosts += amount; defaults.set(hintBoosts, forKey: K.boostHint) }
    @discardableResult
    func consumeHint() -> Bool {
        guard hintBoosts > 0 else { return false }
        hintBoosts -= 1; defaults.set(hintBoosts, forKey: K.boostHint); return true
    }

    func grantExtraLife(_ amount: Int) { extraLifeBoosts += amount; defaults.set(extraLifeBoosts, forKey: K.boostExtraLife) }
    @discardableResult
    func consumeExtraLife() -> Bool {
        guard extraLifeBoosts > 0 else { return false }
        extraLifeBoosts -= 1; defaults.set(extraLifeBoosts, forKey: K.boostExtraLife); return true
    }

    func grantDoubleCoins(_ amount: Int) { doubleCoinsBoosts += amount; defaults.set(doubleCoinsBoosts, forKey: K.boostDoubleCoins) }
    @discardableResult
    func consumeDoubleCoins() -> Bool {
        guard doubleCoinsBoosts > 0 else { return false }
        doubleCoinsBoosts -= 1; defaults.set(doubleCoinsBoosts, forKey: K.boostDoubleCoins); return true
    }

    func grantLucky(_ amount: Int) { luckyBoosts += amount; defaults.set(luckyBoosts, forKey: K.boostLucky) }
    @discardableResult
    func consumeLucky() -> Bool {
        guard luckyBoosts > 0 else { return false }
        luckyBoosts -= 1; defaults.set(luckyBoosts, forKey: K.boostLucky); return true
    }
}
