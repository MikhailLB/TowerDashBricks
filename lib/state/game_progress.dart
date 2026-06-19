import 'package:flutter/foundation.dart';

import '../game/brick_unit.dart';
import '../game/unit_catalog.dart';
import '../services/storage_service.dart';

/// In-memory mirror of [StorageService] that notifies the UI on changes.
class GameProgress extends ChangeNotifier {
  GameProgress(this._storage)
      : _coins = _storage.coins,
        _gems = _storage.gems,
        _trophies = _storage.trophies,
        _ownedUnits = Map<String, int>.from(_storage.ownedUnits),
        _deck = List<String>.from(_storage.deck),
        _highScore = _storage.highScore,
        _highestUnlockedLevel = _storage.highestUnlockedLevel,
        _completedLevels = Set<int>.from(_storage.completedLevels),
        _hintBoosts = _storage.hintBoosts,
        _extraLifeBoosts = _storage.extraLifeBoosts,
        _doubleCoinsBoosts = _storage.doubleCoinsBoosts,
        _luckyBoosts = _storage.luckyBoosts,
        _ownedSkins = List<int>.from(_storage.ownedSkins),
        _selectedSkin = _storage.selectedSkin,
        _tutorialSeen = _storage.tutorialSeen,
        _soundEnabled = _storage.soundEnabled,
        _musicEnabled = _storage.musicEnabled,
        _vibrationEnabled = _storage.vibrationEnabled,
        _musicVolume = _storage.musicVolume,
        _sfxVolume = _storage.sfxVolume;

  final StorageService _storage;

  int _coins;
  int _gems;
  int _trophies;
  final Map<String, int> _ownedUnits;
  List<String> _deck;
  int _highScore;
  int _highestUnlockedLevel;
  final Set<int> _completedLevels;
  int _hintBoosts;
  int _extraLifeBoosts;
  int _doubleCoinsBoosts;
  int _luckyBoosts;
  List<int> _ownedSkins;
  int _selectedSkin;
  bool _tutorialSeen;
  bool _soundEnabled;
  bool _musicEnabled;
  bool _vibrationEnabled;
  double _musicVolume;
  double _sfxVolume;

  int get coins => _coins;
  int get gems => _gems;
  int get trophies => _trophies;
  Map<String, int> get ownedUnits => Map.unmodifiable(_ownedUnits);
  List<String> get deck => List.unmodifiable(_deck);
  int get highScore => _highScore;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get hintBoosts => _hintBoosts;
  int get extraLifeBoosts => _extraLifeBoosts;
  int get doubleCoinsBoosts => _doubleCoinsBoosts;
  int get luckyBoosts => _luckyBoosts;
  List<int> get ownedSkins => List.unmodifiable(_ownedSkins);
  int get selectedSkin => _selectedSkin;
  bool get tutorialSeen => _tutorialSeen;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // --- Coins & score ---

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    await _storage.setCoins(_coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    await _storage.setCoins(_coins);
    notifyListeners();
    return true;
  }

  Future<void> setHighScore(int score) async {
    if (score <= _highScore) return;
    _highScore = score;
    await _storage.setHighScore(_highScore);
    notifyListeners();
  }

  // --- Gems ---

  Future<void> addGems(int amount) async {
    if (amount <= 0) return;
    _gems += amount;
    await _storage.setGems(_gems);
    notifyListeners();
  }

  Future<bool> spendGems(int amount) async {
    if (amount <= 0 || _gems < amount) return false;
    _gems -= amount;
    await _storage.setGems(_gems);
    notifyListeners();
    return true;
  }

  // --- Trophies ---

  Future<void> addTrophies(int delta) async {
    _trophies = (_trophies + delta).clamp(0, 1 << 30);
    await _storage.setTrophies(_trophies);
    notifyListeners();
  }

  // --- Units & deck ---

  int unitLevel(String id) => _ownedUnits[id] ?? 0;
  bool ownsUnit(String id) => _ownedUnits.containsKey(id);
  int get ownedUnitCount => _ownedUnits.length;

  /// Add a unit to the collection. If already owned, level it up by one
  /// (duplicate fusion). Returns true if it was a brand-new unit.
  Future<bool> grantUnit(String id) async {
    final isNew = !_ownedUnits.containsKey(id);
    _ownedUnits[id] = (_ownedUnits[id] ?? 0) + 1;
    await _storage.setOwnedUnits(_ownedUnits);
    notifyListeners();
    return isNew;
  }

  /// Ids of units that leveled up since the player last viewed the collection,
  /// so we can flag them with a "Lv up!" marker.
  final Set<String> _newlyLeveled = {};
  Set<String> get newlyLeveled => Set.unmodifiable(_newlyLeveled);
  bool get hasUnseenLevelUps => _newlyLeveled.isNotEmpty;
  bool isNewlyLeveled(String id) => _newlyLeveled.contains(id);

  void markLevelUpsSeen() {
    if (_newlyLeveled.isEmpty) return;
    _newlyLeveled.clear();
    notifyListeners();
  }

  /// Free training reward: bump the [count] lowest-level owned units by one
  /// level each. Keeps the roster growing so the campaign never hard-walls.
  Future<void> grantFreeLevels(int count) async {
    if (_ownedUnits.isEmpty || count <= 0) return;
    final ids = _ownedUnits.keys.toList()
      ..sort((a, b) => _ownedUnits[a]!.compareTo(_ownedUnits[b]!));
    for (var i = 0; i < count && i < ids.length; i++) {
      _ownedUnits[ids[i]] = _ownedUnits[ids[i]]! + 1;
      _newlyLeveled.add(ids[i]);
    }
    await _storage.setOwnedUnits(_ownedUnits);
    notifyListeners();
  }

  /// Spend coins to raise a unit's level. Returns false if not enough coins.
  Future<bool> upgradeUnit(String id) async {
    final def = unitDefById(id);
    final level = _ownedUnits[id];
    if (def == null || level == null) return false;
    final cost = def.upgradeCost(level);
    if (_coins < cost) return false;
    _coins -= cost;
    _ownedUnits[id] = level + 1;
    _newlyLeveled.add(id);
    await _storage.setCoins(_coins);
    await _storage.setOwnedUnits(_ownedUnits);
    notifyListeners();
    return true;
  }

  Future<void> setDeck(List<String> ids) async {
    _deck = List<String>.from(ids);
    await _storage.setDeck(_deck);
    notifyListeners();
  }

  /// Materialises the saved deck into live battle units (skips unowned ids).
  List<BrickUnit> buildDeckUnits() {
    final out = <BrickUnit>[];
    for (final id in _deck) {
      final def = unitDefById(id);
      final level = _ownedUnits[id];
      if (def == null || level == null) continue;
      out.add(BrickUnit(def: def, level: level));
    }
    return out;
  }

  // --- Levels ---

  Future<void> completeLevel(int levelNumber) async {
    _completedLevels.add(levelNumber);
    await _storage.setCompletedLevels(_completedLevels);
    if (levelNumber >= _highestUnlockedLevel) {
      _highestUnlockedLevel = levelNumber + 1;
      await _storage.setHighestUnlockedLevel(_highestUnlockedLevel);
    }
    notifyListeners();
  }

  bool isLevelUnlocked(int levelNumber) =>
      levelNumber <= _highestUnlockedLevel;

  bool isLevelCompleted(int levelNumber) =>
      _completedLevels.contains(levelNumber);

  // --- Skins ---

  Future<void> setSelectedSkin(int skin) async {
    _selectedSkin = skin;
    await _storage.setSelectedSkin(skin);
    notifyListeners();
  }

  Future<void> setTutorialSeen() async {
    if (_tutorialSeen) return;
    _tutorialSeen = true;
    await _storage.setTutorialSeen(true);
    notifyListeners();
  }

  Future<void> unlockSkin(int skin) async {
    if (_ownedSkins.contains(skin)) return;
    _ownedSkins = [..._ownedSkins, skin]..sort();
    await _storage.addOwnedSkin(skin);
    notifyListeners();
  }

  // --- Power-ups: grant / consume ---

  Future<void> grantHint(int amount) async {
    _hintBoosts += amount;
    await _storage.setHintBoosts(_hintBoosts);
    notifyListeners();
  }

  Future<bool> consumeHint() async {
    if (_hintBoosts <= 0) return false;
    _hintBoosts--;
    await _storage.setHintBoosts(_hintBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantExtraLife(int amount) async {
    _extraLifeBoosts += amount;
    await _storage.setExtraLifeBoosts(_extraLifeBoosts);
    notifyListeners();
  }

  Future<bool> consumeExtraLife() async {
    if (_extraLifeBoosts <= 0) return false;
    _extraLifeBoosts--;
    await _storage.setExtraLifeBoosts(_extraLifeBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantDoubleCoins(int amount) async {
    _doubleCoinsBoosts += amount;
    await _storage.setDoubleCoinsBoosts(_doubleCoinsBoosts);
    notifyListeners();
  }

  Future<bool> consumeDoubleCoins() async {
    if (_doubleCoinsBoosts <= 0) return false;
    _doubleCoinsBoosts--;
    await _storage.setDoubleCoinsBoosts(_doubleCoinsBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantLucky(int amount) async {
    _luckyBoosts += amount;
    await _storage.setLuckyBoosts(_luckyBoosts);
    notifyListeners();
  }

  Future<bool> consumeLucky() async {
    if (_luckyBoosts <= 0) return false;
    _luckyBoosts--;
    await _storage.setLuckyBoosts(_luckyBoosts);
    notifyListeners();
    return true;
  }

  // --- Audio / prefs ---

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _storage.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _storage.setMusicEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _storage.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    await _storage.setMusicVolume(_musicVolume);
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    await _storage.setSfxVolume(_sfxVolume);
    notifyListeners();
  }
}
