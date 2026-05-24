import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for player progress and preferences.
class StorageService {
  StorageService._(this._prefs);

  // --- Keys ---
  static const _kHighScore = 'st_high_score';
  static const _kCoins = 'st_coins';
  static const _kOwnedSkins = 'st_owned_skins';
  static const _kSelectedSkin = 'st_selected_skin';
  static const _kHighestUnlockedLevel = 'st_highest_unlocked_level';
  static const _kCompletedLevels = 'st_completed_levels';
  // Boosts
  static const _kBoostSlowHook = 'st_boost_slow_hook';
  static const _kBoostSecondChance = 'st_boost_second_chance';
  static const _kBoostDoubleCoins = 'st_boost_double_coins';
  static const _kBoostGhostBlock = 'st_boost_ghost_block';
  static const _kBoostSpeedFreeze = 'st_boost_speed_freeze';
  static const _kBoostWideBase = 'st_boost_wide_base';
  static const _kBoostLucky = 'st_boost_lucky';
  // Audio
  static const _kSoundEnabled = 'st_sound_enabled';
  static const _kMusicEnabled = 'st_music_enabled';
  static const _kVibrationEnabled = 'st_vibration_enabled';
  static const _kMusicVolume = 'st_music_volume';
  static const _kSfxVolume = 'st_sfx_volume';

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService._(prefs);
    await service._seedDefaults();
    return service;
  }

  Future<void> _seedDefaults() async {
    if (!_prefs.containsKey(_kOwnedSkins)) {
      // Skin 1 is the starting unlocked skin (octagonal-window house).
      // Images were swapped: tdb_brick_01 now shows the octagonal house.
      await _prefs.setStringList(_kOwnedSkins, ['1']);
    }
    if (!_prefs.containsKey(_kSelectedSkin)) {
      await _prefs.setInt(_kSelectedSkin, 0);
    }
    if (!_prefs.containsKey(_kHighestUnlockedLevel)) {
      await _prefs.setInt(_kHighestUnlockedLevel, 1);
    }
    if (!_prefs.containsKey(_kSoundEnabled)) {
      await _prefs.setBool(_kSoundEnabled, true);
    }
    if (!_prefs.containsKey(_kMusicEnabled)) {
      await _prefs.setBool(_kMusicEnabled, true);
    }
    if (!_prefs.containsKey(_kVibrationEnabled)) {
      await _prefs.setBool(_kVibrationEnabled, true);
    }
    if (!_prefs.containsKey(_kMusicVolume)) {
      await _prefs.setDouble(_kMusicVolume, 0.6);
    }
    if (!_prefs.containsKey(_kSfxVolume)) {
      await _prefs.setDouble(_kSfxVolume, 0.8);
    }
  }

  // --- Getters ---
  int get highScore => _prefs.getInt(_kHighScore) ?? 0;
  int get coins => _prefs.getInt(_kCoins) ?? 0;
  int get highestUnlockedLevel => _prefs.getInt(_kHighestUnlockedLevel) ?? 1;
  Set<int> get completedLevels =>
      (_prefs.getStringList(_kCompletedLevels) ?? const [])
          .map(int.parse)
          .toSet();
  int get slowHookBoosts => _prefs.getInt(_kBoostSlowHook) ?? 0;
  int get secondChanceBoosts => _prefs.getInt(_kBoostSecondChance) ?? 0;
  int get doubleCoinsBoosts => _prefs.getInt(_kBoostDoubleCoins) ?? 0;
  int get ghostBlockBoosts => _prefs.getInt(_kBoostGhostBlock) ?? 0;
  int get speedFreezeBoosts => _prefs.getInt(_kBoostSpeedFreeze) ?? 0;
  int get wideBaseBoosts => _prefs.getInt(_kBoostWideBase) ?? 0;
  int get luckyBoosts => _prefs.getInt(_kBoostLucky) ?? 0;
  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  bool get musicEnabled => _prefs.getBool(_kMusicEnabled) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_kVibrationEnabled) ?? true;
  double get musicVolume => _prefs.getDouble(_kMusicVolume) ?? 0.6;
  double get sfxVolume => _prefs.getDouble(_kSfxVolume) ?? 0.8;
  List<int> get ownedSkins =>
      (_prefs.getStringList(_kOwnedSkins) ?? const ['1'])
          .map(int.parse)
          .toList()
        ..sort();
  int get selectedSkin => _prefs.getInt(_kSelectedSkin) ?? 0;

  // --- Setters ---
  Future<void> setHighScore(int v) => _prefs.setInt(_kHighScore, v);
  Future<void> setCoins(int v) => _prefs.setInt(_kCoins, v);
  Future<void> setHighestUnlockedLevel(int v) =>
      _prefs.setInt(_kHighestUnlockedLevel, v);
  Future<void> setCompletedLevels(Set<int> levels) => _prefs.setStringList(
        _kCompletedLevels,
        levels.map((e) => e.toString()).toList(),
      );
  Future<void> setSlowHookBoosts(int v) => _prefs.setInt(_kBoostSlowHook, v);
  Future<void> setSecondChanceBoosts(int v) =>
      _prefs.setInt(_kBoostSecondChance, v);
  Future<void> setDoubleCoinsBoosts(int v) =>
      _prefs.setInt(_kBoostDoubleCoins, v);
  Future<void> setGhostBlockBoosts(int v) =>
      _prefs.setInt(_kBoostGhostBlock, v);
  Future<void> setSpeedFreezeBoosts(int v) =>
      _prefs.setInt(_kBoostSpeedFreeze, v);
  Future<void> setWideBaseBoosts(int v) => _prefs.setInt(_kBoostWideBase, v);
  Future<void> setLuckyBoosts(int v) => _prefs.setInt(_kBoostLucky, v);
  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSoundEnabled, v);
  Future<void> setMusicEnabled(bool v) => _prefs.setBool(_kMusicEnabled, v);
  Future<void> setVibrationEnabled(bool v) =>
      _prefs.setBool(_kVibrationEnabled, v);
  Future<void> setMusicVolume(double v) => _prefs.setDouble(_kMusicVolume, v);
  Future<void> setSfxVolume(double v) => _prefs.setDouble(_kSfxVolume, v);
  Future<void> setSelectedSkin(int skin) =>
      _prefs.setInt(_kSelectedSkin, skin);

  Future<void> addOwnedSkin(int skin) async {
    final list = ownedSkins;
    if (!list.contains(skin)) {
      list.add(skin);
      await _prefs.setStringList(
        _kOwnedSkins,
        list.map((e) => e.toString()).toList(),
      );
    }
  }
}
