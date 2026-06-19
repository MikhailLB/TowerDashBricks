import '../app/tdb_assets.dart';
import 'battle_setup.dart';
import 'unit_catalog.dart';
import 'unit_class.dart';

/// A campaign chapter: a themed run of waves ending in a boss.
class Chapter {
  const Chapter({
    required this.index,
    required this.name,
    required this.tagline,
    required this.background,
    required this.classPool,
    required this.bossAsset,
    required this.bossName,
    required this.bossAbility,
    this.waveCount = 9,
  });

  final int index;
  final String name;
  final String tagline;
  final String background;
  final List<UnitClass> classPool;
  final String bossAsset;
  final String bossName;
  final BossAbility bossAbility;
  final int waveCount;
}

const List<Chapter> chapters = [
  Chapter(
    index: 0,
    name: 'Foundations',
    tagline: 'Hold the line with steel and grit',
    background: TdbAssets.sky,
    classPool: [UnitClass.warrior, UnitClass.archer, UnitClass.tank],
    bossAsset: TdbAssets.bossForeman,
    bossName: 'The Foreman',
    bossAbility: BossAbility.shockwave,
  ),
  Chapter(
    index: 1,
    name: 'Ranged Yard',
    tagline: 'Arrows and arcane fill the air',
    background: TdbAssets.bgSunset,
    classPool: [UnitClass.archer, UnitClass.mage, UnitClass.sniper],
    bossAsset: TdbAssets.bossCrane,
    bossName: 'Rust Crane',
    bossAbility: BossAbility.wreckingBall,
  ),
  Chapter(
    index: 2,
    name: 'Demolition Zone',
    tagline: 'Everything that can blow up, will',
    background: TdbAssets.bgIndustrial,
    classPool: [UnitClass.bomber, UnitClass.golem, UnitClass.warrior],
    bossAsset: TdbAssets.bossWrecker,
    bossName: 'The Wrecker',
    bossAbility: BossAbility.siphon,
  ),
  Chapter(
    index: 3,
    name: 'The Megastructure',
    tagline: 'Every class, no mercy',
    background: TdbAssets.bgNight,
    classPool: UnitClass.values,
    bossAsset: TdbAssets.bossForeman,
    bossName: 'Overseer Prime',
    bossAbility: BossAbility.shockwave,
  ),
];

int get totalWaves =>
    chapters.fold(0, (sum, c) => sum + c.waveCount);

/// Maps a 1-based global wave number to its (chapter, waveInChapter 1-based).
({Chapter chapter, int waveInChapter}) locateWave(int globalWave) {
  var remaining = globalWave;
  for (final c in chapters) {
    if (remaining <= c.waveCount) {
      return (chapter: c, waveInChapter: remaining);
    }
    remaining -= c.waveCount;
  }
  final last = chapters.last;
  return (chapter: last, waveInChapter: last.waveCount);
}

Rarity _rarityForWave(int globalWave, bool boss) {
  if (boss) {
    if (globalWave >= 27) return Rarity.legendary;
    if (globalWave >= 18) return Rarity.epic;
    return Rarity.rare;
  }
  if (globalWave >= 28) return Rarity.epic;
  if (globalWave >= 14) return Rarity.rare;
  return Rarity.common;
}

/// Builds the battle setup for a 1-based global wave number.
BattleSetup campaignWave(int globalWave) {
  final loc = locateWave(globalWave);
  final chapter = loc.chapter;
  final waveInChapter = loc.waveInChapter;
  final isBoss = waveInChapter == chapter.waveCount;

  // Smooth ramp: enemy count and level grow slowly so each wave is only a
  // little tougher than the last.
  final level = (1 + globalWave ~/ 3).clamp(1, 12);
  final rarity = _rarityForWave(globalWave, isBoss);

  if (isBoss) {
    return _bossWave(chapter, globalWave, level, rarity, waveInChapter);
  }

  final pool = chapter.classPool;
  final size = (2 + (globalWave - 1) ~/ 4).clamp(2, 6);
  final enemies = <EnemySpec>[
    for (var i = 0; i < size; i++)
      EnemySpec(pool[(globalWave + i) % pool.length], rarity, level),
  ];

  final coins = 40 + globalWave * 14;
  final gems = globalWave % 3 == 0 ? 2 : 0;

  return BattleSetup(
    title: 'Wave $waveInChapter',
    subtitle: chapter.name,
    enemies: enemies,
    coinReward: coins,
    gemReward: gems,
    backgroundAsset: chapter.background,
  );
}

/// Builds a solo-boss showdown: one oversized boss with a signature ability,
/// tuned to be a wall that pushes the player to upgrade before clearing it.
BattleSetup _bossWave(
    Chapter chapter, int globalWave, int level, Rarity rarity, int waveInChapter) {
  final bossLevel = level + 3;
  final hpMult = 3.2 + chapter.index * 0.5;
  final atkMult = 1.4 + chapter.index * 0.15;
  final hp = (unitDef(UnitClass.tank, rarity).healthAt(bossLevel) * hpMult).round();
  final atk =
      (unitDef(UnitClass.warrior, rarity).attackAt(bossLevel) * atkMult).round();

  final boss = BossSpec(
    asset: chapter.bossAsset,
    name: chapter.bossName,
    ability: chapter.bossAbility,
    hp: hp,
    atk: atk,
  );

  return BattleSetup(
    title: chapter.bossName,
    subtitle: 'BOSS · ${chapter.name}',
    enemies: const [],
    coinReward: (60 + globalWave * 18) * 2,
    gemReward: 10,
    backgroundAsset: chapter.background,
    isBoss: true,
    bossAsset: chapter.bossAsset,
    boss: boss,
  );
}

/// Units unlocked by clearing a given 1-based global wave (milestone rewards).
/// The player starts with Warrior + Archer; the rest are earned gradually so
/// the roster grows at a steady pace rather than all at once.
String? unitUnlockForWave(int globalWave) {
  switch (globalWave) {
    case 3:
      return unitDef(UnitClass.tank, Rarity.common).id;
    case 6:
      return unitDef(UnitClass.healer, Rarity.common).id;
    case 10:
      return unitDef(UnitClass.mage, Rarity.common).id;
    case 15:
      return unitDef(UnitClass.bomber, Rarity.common).id;
    case 20:
      return unitDef(UnitClass.golem, Rarity.rare).id;
    case 25:
      return unitDef(UnitClass.sniper, Rarity.rare).id;
  }
  return null;
}
