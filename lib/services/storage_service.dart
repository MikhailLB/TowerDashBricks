import 'package:shared_preferences/shared_preferences.dart';

import '../game/unit_catalog.dart';

/// Persistent storage for player progress and preferences.
class StorageService {
  StorageService._(this._prefs);

  // --- Keys ---
  static const _kHighScore = 'st_high_score';
  static const _kCoins = 'st_coins';
  static const _kGems = 'st_gems';
  static const _kTrophies = 'st_trophies';
  static const _kOwnedUnits = 'st_owned_units';
  static const _kDeck = 'st_deck';
  static const _kOwnedSkins = 'st_owned_skins';
  static const _kSelectedSkin = 'st_selected_skin';
  static const _kHighestUnlockedLevel = 'st_highest_unlocked_level';
  static const _kCompletedLevels = 'st_completed_levels';
  static const _kTutorialSeen = 'st_tutorial_seen';
  // Power-ups
  static const _kBoostHint = 'st_boost_hint';
  static const _kBoostExtraLife = 'st_boost_extra_life';
  static const _kBoostDoubleCoins = 'st_boost_double_coins';
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
      // Skin 1 is the starting unlocked skin on white branch.
      // (Skin 5 is Coming Soon here — that's only default in gray branch.)
      await _prefs.setStringList(_kOwnedSkins, ['1']);
    }
    if (!_prefs.containsKey(_kSelectedSkin)) {
      await _prefs.setInt(_kSelectedSkin, 0);
    }
    if (!_prefs.containsKey(_kHighestUnlockedLevel)) {
      await _prefs.setInt(_kHighestUnlockedLevel, 1);
    }
    if (!_prefs.containsKey(_kOwnedUnits)) {
      // Start with one common of each class at level 1.
      await _prefs.setStringList(
        _kOwnedUnits,
        [for (final id in starterUnitIds) '$id:1'],
      );
    }
    if (!_prefs.containsKey(_kDeck)) {
      await _prefs.setStringList(_kDeck, List<String>.from(starterUnitIds));
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
  int get gems => _prefs.getInt(_kGems) ?? 0;
  int get trophies => _prefs.getInt(_kTrophies) ?? 0;

  /// Owned units as a map of unitId -> level.
  Map<String, int> get ownedUnits {
    final list = _prefs.getStringList(_kOwnedUnits) ?? const [];
    final map = <String, int>{};
    for (final entry in list) {
      final i = entry.lastIndexOf(':');
      if (i <= 0) continue;
      final id = entry.substring(0, i);
      final level = int.tryParse(entry.substring(i + 1)) ?? 1;
      map[id] = level;
    }
    return map;
  }

  /// Ordered deck (list of unit ids).
  List<String> get deck => _prefs.getStringList(_kDeck) ?? const [];
  int get highestUnlockedLevel => _prefs.getInt(_kHighestUnlockedLevel) ?? 1;
  Set<int> get completedLevels =>
      (_prefs.getStringList(_kCompletedLevels) ?? const [])
          .map(int.parse)
          .toSet();
  int get hintBoosts => _prefs.getInt(_kBoostHint) ?? 0;
  int get extraLifeBoosts => _prefs.getInt(_kBoostExtraLife) ?? 0;
  int get doubleCoinsBoosts => _prefs.getInt(_kBoostDoubleCoins) ?? 0;
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
  bool get tutorialSeen => _prefs.getBool(_kTutorialSeen) ?? false;

  // --- Setters ---
  Future<void> setHighScore(int v) => _prefs.setInt(_kHighScore, v);
  Future<void> setCoins(int v) => _prefs.setInt(_kCoins, v);
  Future<void> setGems(int v) => _prefs.setInt(_kGems, v);
  Future<void> setTrophies(int v) => _prefs.setInt(_kTrophies, v);
  Future<void> setOwnedUnits(Map<String, int> units) => _prefs.setStringList(
        _kOwnedUnits,
        [for (final e in units.entries) '${e.key}:${e.value}'],
      );
  Future<void> setDeck(List<String> ids) =>
      _prefs.setStringList(_kDeck, ids);
  Future<void> setHighestUnlockedLevel(int v) =>
      _prefs.setInt(_kHighestUnlockedLevel, v);
  Future<void> setCompletedLevels(Set<int> levels) => _prefs.setStringList(
        _kCompletedLevels,
        levels.map((e) => e.toString()).toList(),
      );
  Future<void> setHintBoosts(int v) => _prefs.setInt(_kBoostHint, v);
  Future<void> setExtraLifeBoosts(int v) => _prefs.setInt(_kBoostExtraLife, v);
  Future<void> setDoubleCoinsBoosts(int v) =>
      _prefs.setInt(_kBoostDoubleCoins, v);
  Future<void> setLuckyBoosts(int v) => _prefs.setInt(_kBoostLucky, v);
  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSoundEnabled, v);
  Future<void> setMusicEnabled(bool v) => _prefs.setBool(_kMusicEnabled, v);
  Future<void> setVibrationEnabled(bool v) =>
      _prefs.setBool(_kVibrationEnabled, v);
  Future<void> setMusicVolume(double v) => _prefs.setDouble(_kMusicVolume, v);
  Future<void> setSfxVolume(double v) => _prefs.setDouble(_kSfxVolume, v);
  Future<void> setSelectedSkin(int skin) =>
      _prefs.setInt(_kSelectedSkin, skin);
  Future<void> setTutorialSeen(bool v) => _prefs.setBool(_kTutorialSeen, v);

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
