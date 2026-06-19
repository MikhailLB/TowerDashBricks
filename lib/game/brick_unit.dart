import 'unit_class.dart';

/// Immutable template for a collectible unit (class + rarity variant).
class UnitDef {
  const UnitDef({
    required this.clazz,
    required this.rarity,
    required this.name,
  });

  final UnitClass clazz;
  final Rarity rarity;
  final String name;

  /// Stable id, e.g. "archer_rare".
  String get id => '${clazz.id}_${rarity.id}';

  TargetMode get targetMode => clazz.targetMode;

  static const int _baseAtk = 16;
  static const int _baseHp = 56;

  double _levelFactor(int level) => 1 + 0.16 * (level - 1);

  int attackAt(int level) {
    final bias = clazz.statBias.$1;
    return (_baseAtk * bias * rarity.statMult * _levelFactor(level)).round();
  }

  int healthAt(int level) {
    final bias = clazz.statBias.$2;
    return (_baseHp * bias * rarity.statMult * _levelFactor(level)).round();
  }

  /// Coins needed to level this unit from [level] to level+1.
  int upgradeCost(int level) =>
      (40 * (rarity.stars) * level * 1.25).round();

  int get powerScore => attackAt(1) + (healthAt(1) ~/ 3);
}

/// A live unit inside a battle. Carries mutable HP/buffs.
class BrickUnit {
  BrickUnit({
    required this.def,
    required this.level,
    this.displayAsset,
    this.bossAbility,
    this.bossName,
    int? hpOverride,
    int? atkOverride,
  })  : atk = atkOverride ?? def.attackAt(level),
        maxHp = hpOverride ?? def.healthAt(level),
        hp = hpOverride ?? def.healthAt(level);

  /// Builds a solo campaign boss: a single oversized unit with a custom sprite,
  /// big stats and a signature ability. Uses the [tank] front-line behaviour as
  /// its baseline attack pattern.
  factory BrickUnit.boss({
    required String asset,
    required String name,
    required BossAbility ability,
    required int hp,
    required int atk,
    int level = 1,
  }) {
    return BrickUnit(
      def: UnitDef(clazz: UnitClass.tank, rarity: Rarity.legendary, name: name),
      level: level,
      displayAsset: asset,
      bossAbility: ability,
      bossName: name,
      hpOverride: hp,
      atkOverride: atk,
    );
  }

  final UnitDef def;
  final int level;

  /// Sprite override (used by bosses); falls back to the class sprite.
  final String? displayAsset;
  final BossAbility? bossAbility;
  final String? bossName;
  bool get isBoss => bossAbility != null;

  int atk;
  int maxHp;
  int hp;
  int shield = 0;

  UnitClass get clazz => def.clazz;
  Rarity get rarity => def.rarity;

  bool get isAlive => hp > 0;
  double get hpFraction => maxHp == 0 ? 0 : (hp / maxHp).clamp(0.0, 1.0);

  /// Apply [amount] of damage (after shield). Returns the HP actually lost.
  int takeDamage(int amount) {
    if (amount <= 0) return 0;
    var remaining = amount;
    if (shield > 0) {
      final absorbed = shield >= remaining ? remaining : shield;
      shield -= absorbed;
      remaining -= absorbed;
    }
    final before = hp;
    hp = (hp - remaining).clamp(0, maxHp);
    return before - hp;
  }

  /// Heal up to maxHp. Returns the HP actually restored.
  int heal(int amount) {
    if (amount <= 0 || hp <= 0) return 0;
    final before = hp;
    hp = (hp + amount).clamp(0, maxHp);
    return hp - before;
  }
}
