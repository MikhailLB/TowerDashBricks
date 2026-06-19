import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/tdb_assets.dart';
import 'battle_setup.dart';
import 'unit_class.dart';

/// Competitive leagues, derived from trophy count.
enum League { stone, bronze, silver, gold, diamond }

extension LeagueInfo on League {
  String get label {
    switch (this) {
      case League.stone:
        return 'Stone';
      case League.bronze:
        return 'Bronze';
      case League.silver:
        return 'Silver';
      case League.gold:
        return 'Gold';
      case League.diamond:
        return 'Diamond';
    }
  }

  int get minTrophies {
    switch (this) {
      case League.stone:
        return 0;
      case League.bronze:
        return 200;
      case League.silver:
        return 500;
      case League.gold:
        return 900;
      case League.diamond:
        return 1400;
    }
  }

  Color get color {
    switch (this) {
      case League.stone:
        return const Color(0xFF9AA7B8);
      case League.bronze:
        return const Color(0xFFCD7F45);
      case League.silver:
        return const Color(0xFFC7D0DE);
      case League.gold:
        return const Color(0xFFFFC83D);
      case League.diamond:
        return const Color(0xFF54E0FF);
    }
  }
}

League leagueForTrophies(int trophies) {
  League result = League.stone;
  for (final l in League.values) {
    if (trophies >= l.minTrophies) result = l;
  }
  return result;
}

/// Random themed opponent name for flavor.
const List<String> _botNames = [
  'IronClad', 'BlockBuster', 'Maverick', 'RebarRex', 'SkyHammer',
  'ConcreteKing', 'TheArchitect', 'BoltRunner', 'GravelGuru', 'Steelheart',
  'Demolisher', 'TowerTitan', 'BrickByrne', 'CraneZilla', 'FoundationFox',
];

/// Builds a procedurally-scaled bot opponent for the arena.
class ArenaMatch {
  ArenaMatch({
    required this.opponentName,
    required this.setup,
    required this.trophyGain,
    required this.trophyLoss,
  });

  final String opponentName;
  final BattleSetup setup;
  final int trophyGain;
  final int trophyLoss;
}

ArenaMatch generateArenaMatch(int trophies, {int? seed}) {
  final rng = math.Random(seed ?? DateTime.now().millisecondsSinceEpoch);
  final name = _botNames[rng.nextInt(_botNames.length)];

  // Strength scales with trophies.
  final tier = (trophies ~/ 150);
  final size = (4 + tier ~/ 2).clamp(3, 6);
  final level = (2 + tier).clamp(1, 14);

  Rarity rarity;
  if (trophies >= 1400) {
    rarity = Rarity.legendary;
  } else if (trophies >= 800) {
    rarity = Rarity.epic;
  } else if (trophies >= 350) {
    rarity = Rarity.rare;
  } else {
    rarity = Rarity.common;
  }

  final classes = List<UnitClass>.from(UnitClass.values)..shuffle(rng);
  final enemies = <EnemySpec>[
    for (var i = 0; i < size; i++)
      EnemySpec(classes[i % classes.length], rarity, level),
  ];

  final setup = BattleSetup(
    title: name,
    subtitle: 'Arena Challenger',
    enemies: enemies,
    coinReward: 60 + tier * 20,
    gemReward: 1,
    backgroundAsset:
        TdbAssets.backgrounds[rng.nextInt(TdbAssets.backgrounds.length)],
  );

  return ArenaMatch(
    opponentName: name,
    setup: setup,
    trophyGain: 28 + rng.nextInt(8),
    trophyLoss: 18 + rng.nextInt(8),
  );
}
