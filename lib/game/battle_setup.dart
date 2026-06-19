import 'brick_unit.dart';
import 'unit_catalog.dart';
import 'unit_class.dart';

/// A single enemy slot specification.
class EnemySpec {
  const EnemySpec(this.clazz, this.rarity, this.level);
  final UnitClass clazz;
  final Rarity rarity;
  final int level;

  BrickUnit build() => BrickUnit(def: unitDef(clazz, rarity), level: level);
}

/// Stats + identity for a solo boss encounter.
class BossSpec {
  const BossSpec({
    required this.asset,
    required this.name,
    required this.ability,
    required this.hp,
    required this.atk,
  });

  final String asset;
  final String name;
  final BossAbility ability;
  final int hp;
  final int atk;

  BrickUnit build() =>
      BrickUnit.boss(asset: asset, name: name, ability: ability, hp: hp, atk: atk);

  int get power => atk + hp ~/ 3;
}

/// Everything needed to start one battle (campaign wave or arena match).
class BattleSetup {
  const BattleSetup({
    required this.title,
    required this.subtitle,
    required this.enemies,
    required this.coinReward,
    required this.gemReward,
    required this.backgroundAsset,
    this.isBoss = false,
    this.bossAsset,
    this.boss,
    this.deckSlots = 6,
  });

  final String title;
  final String subtitle;
  final List<EnemySpec> enemies;
  final int coinReward;
  final int gemReward;
  final String backgroundAsset;
  final bool isBoss;
  final String? bossAsset;

  /// When set, this is a solo-boss encounter: the enemy side is a single
  /// powerful boss with its own ability instead of a team.
  final BossSpec? boss;
  final int deckSlots;

  bool get isSoloBoss => boss != null;

  List<BrickUnit> buildEnemyUnits() {
    if (boss != null) return [boss!.build()];
    return [for (final e in enemies) e.build()];
  }

  int get enemyPower {
    if (boss != null) return boss!.power;
    var p = 0;
    for (final e in enemies) {
      final d = unitDef(e.clazz, e.rarity);
      p += d.attackAt(e.level) + d.healthAt(e.level) ~/ 3;
    }
    return p;
  }
}
