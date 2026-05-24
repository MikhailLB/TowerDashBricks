/// Describes a single game level for TowerDash Bricks Rush mode.
/// Each level has a target brick count, countdown timer, crane speed, wind, and coin reward.
class LevelConfig {
  const LevelConfig({
    required this.levelNumber,
    required this.levelName,
    required this.targetBlocks,
    required this.timeLimit,
    required this.craneSpeedMultiplier,
    required this.overlapMultiplier,
    required this.windStrength,
    required this.coinReward,
  });

  /// 1-based level index.
  final int levelNumber;

  /// Display name for the level.
  final String levelName;

  /// Bricks that must be placed to complete the level.
  final int targetBlocks;

  /// Countdown timer in seconds.
  final int timeLimit;

  /// Divides the crane half-period — values > 1 make the crane faster.
  final double craneSpeedMultiplier;

  /// Multiplies [BrickConstants.minOverlapToCount] — values > 1 require
  /// more precise placements.
  final double overlapMultiplier;

  /// Wind gust strength: 0 = none, 0.5 = light, 1.5 = medium, 3.0 = strong.
  final double windStrength;

  /// Coins awarded on level completion.
  final int coinReward;

  String get displayName => levelName;
}

/// All predefined levels — Brick Tower Rush.
const levels = <LevelConfig>[
  LevelConfig(
    levelNumber: 1,
    levelName: 'Street Level',
    targetBlocks: 5,
    timeLimit: 60,
    craneSpeedMultiplier: 1.0,
    overlapMultiplier: 1.0,
    windStrength: 0,
    coinReward: 50,
  ),
  LevelConfig(
    levelNumber: 2,
    levelName: 'Second Story',
    targetBlocks: 7,
    timeLimit: 60,
    craneSpeedMultiplier: 1.1,
    overlapMultiplier: 1.0,
    windStrength: 0,
    coinReward: 75,
  ),
  LevelConfig(
    levelNumber: 3,
    levelName: 'Third Block',
    targetBlocks: 9,
    timeLimit: 55,
    craneSpeedMultiplier: 1.2,
    overlapMultiplier: 1.05,
    windStrength: 0,
    coinReward: 100,
  ),
  LevelConfig(
    levelNumber: 4,
    levelName: 'Fourth Rise',
    targetBlocks: 11,
    timeLimit: 55,
    craneSpeedMultiplier: 1.3,
    overlapMultiplier: 1.1,
    windStrength: 0,
    coinReward: 130,
  ),
  LevelConfig(
    levelNumber: 5,
    levelName: 'High Five',
    targetBlocks: 13,
    timeLimit: 50,
    craneSpeedMultiplier: 1.4,
    overlapMultiplier: 1.15,
    windStrength: 0,
    coinReward: 160,
  ),
  LevelConfig(
    levelNumber: 6,
    levelName: 'Wind Level',
    targetBlocks: 15,
    timeLimit: 50,
    craneSpeedMultiplier: 1.5,
    overlapMultiplier: 1.2,
    windStrength: 0.5,
    coinReward: 200,
  ),
  LevelConfig(
    levelNumber: 7,
    levelName: 'Sky Block',
    targetBlocks: 17,
    timeLimit: 45,
    craneSpeedMultiplier: 1.6,
    overlapMultiplier: 1.25,
    windStrength: 0.5,
    coinReward: 240,
  ),
  LevelConfig(
    levelNumber: 8,
    levelName: 'Cloud Rush',
    targetBlocks: 19,
    timeLimit: 40,
    craneSpeedMultiplier: 1.7,
    overlapMultiplier: 1.3,
    windStrength: 1.5,
    coinReward: 280,
  ),
  LevelConfig(
    levelNumber: 9,
    levelName: 'Tower Sprint',
    targetBlocks: 22,
    timeLimit: 35,
    craneSpeedMultiplier: 1.8,
    overlapMultiplier: 1.35,
    windStrength: 1.5,
    coinReward: 320,
  ),
  LevelConfig(
    levelNumber: 10,
    levelName: 'Penthouse Rush',
    targetBlocks: 25,
    timeLimit: 30,
    craneSpeedMultiplier: 2.0,
    overlapMultiplier: 1.4,
    windStrength: 3.0,
    coinReward: 400,
  ),
];
