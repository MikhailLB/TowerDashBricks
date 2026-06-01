/// Blueprint puzzle (nonogram) level data.
///
/// Each level is a "blueprint" the player reconstructs by laying bricks into a
/// grid following the numeric clues derived from the solution picture.
/// The art is authored as rows of characters: `#` = brick, anything else = gap.
class PuzzleLevel {
  PuzzleLevel({
    required this.levelNumber,
    required this.name,
    required this.rowsArt,
    required this.coinReward,
    required this.lives,
  })  : rowCount = rowsArt.length,
        colCount = rowsArt.isEmpty ? 0 : rowsArt.first.length {
    assert(
      rowsArt.every((r) => r.length == colCount),
      'Level $levelNumber "$name": all rows must have width $colCount',
    );
  }

  /// 1-based level index.
  final int levelNumber;

  /// Display name of the blueprint.
  final String name;

  /// Solution art — one string per row, `#` marks a brick cell.
  final List<String> rowsArt;

  /// Coins awarded on completion.
  final int coinReward;

  /// Allowed mistakes before the blueprint is scrapped.
  final int lives;

  final int rowCount;
  final int colCount;

  /// Total brick cells in the solution.
  late final int brickCount = () {
    var n = 0;
    for (final row in rowsArt) {
      for (var i = 0; i < row.length; i++) {
        if (row[i] == '#') n++;
      }
    }
    return n;
  }();

  bool solutionAt(int r, int c) => rowsArt[r][c] == '#';

  /// Run-length clues for each row, top to bottom.
  late final List<List<int>> rowClues =
      List.generate(rowCount, (r) => _runs((c) => solutionAt(r, c), colCount));

  /// Run-length clues for each column, left to right.
  late final List<List<int>> colClues =
      List.generate(colCount, (c) => _runs((r) => solutionAt(r, c), rowCount));

  static List<int> _runs(bool Function(int) filled, int length) {
    final runs = <int>[];
    var current = 0;
    for (var i = 0; i < length; i++) {
      if (filled(i)) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    return runs.isEmpty ? const [0] : runs;
  }
}

/// All Blueprint puzzles, ordered by difficulty.
final List<PuzzleLevel> puzzleLevels = <PuzzleLevel>[
  PuzzleLevel(
    levelNumber: 1,
    name: 'Window Frame',
    coinReward: 50,
    lives: 3,
    rowsArt: const [
      '#####',
      '#...#',
      '#...#',
      '#...#',
      '#####',
    ],
  ),
  PuzzleLevel(
    levelNumber: 2,
    name: 'Crane Hook',
    coinReward: 60,
    lives: 3,
    rowsArt: const [
      '..#..',
      '.###.',
      '#####',
      '..#..',
      '..#..',
    ],
  ),
  PuzzleLevel(
    levelNumber: 3,
    name: 'Keystone',
    coinReward: 80,
    lives: 3,
    rowsArt: const [
      '..##..',
      '.####.',
      '######',
      '######',
      '.####.',
      '..##..',
    ],
  ),
  PuzzleLevel(
    levelNumber: 4,
    name: 'Brick House',
    coinReward: 100,
    lives: 4,
    rowsArt: const [
      '..###..',
      '.#####.',
      '#######',
      '#.....#',
      '#.###.#',
      '#.#.#.#',
      '#######',
    ],
  ),
  PuzzleLevel(
    levelNumber: 5,
    name: 'Master Key',
    coinReward: 130,
    lives: 4,
    rowsArt: const [
      '..####..',
      '.#....#.',
      '.#....#.',
      '..####..',
      '...##...',
      '...##...',
      '...###..',
      '...##...',
    ],
  ),
  PuzzleLevel(
    levelNumber: 6,
    name: 'Foreman Star',
    coinReward: 160,
    lives: 4,
    rowsArt: const [
      '...##...',
      '...##...',
      '########',
      '.######.',
      '..####..',
      '.######.',
      '.#....#.',
      '##....##',
    ],
  ),
  PuzzleLevel(
    levelNumber: 7,
    name: 'Heart of the City',
    coinReward: 200,
    lives: 5,
    rowsArt: const [
      '..##..##..',
      '.########.',
      '##########',
      '##########',
      '##########',
      '.########.',
      '.########.',
      '..######..',
      '...####...',
      '....##....',
    ],
  ),
  PuzzleLevel(
    levelNumber: 8,
    name: 'Skyscraper',
    coinReward: 240,
    lives: 5,
    rowsArt: const [
      '...####...',
      '...####...',
      '..######..',
      '..#.##.#..',
      '..######..',
      '..#.##.#..',
      '..######..',
      '.########.',
      '#.######.#',
      '##########',
    ],
  ),
  PuzzleLevel(
    levelNumber: 9,
    name: 'Gear Works',
    coinReward: 300,
    lives: 5,
    rowsArt: const [
      '...####...',
      '.#.####.#.',
      '.########.',
      '###.##.###',
      '##......##',
      '##......##',
      '###.##.###',
      '.########.',
      '.#.####.#.',
      '...####...',
    ],
  ),
  PuzzleLevel(
    levelNumber: 10,
    name: 'Battlements',
    coinReward: 400,
    lives: 5,
    rowsArt: const [
      '#.#.#.#.#.',
      '##########',
      '##########',
      '#.######.#',
      '#.#....#.#',
      '#.#.##.#.#',
      '#.#.##.#.#',
      '##########',
      '##########',
      '##########',
    ],
  ),
  PuzzleLevel(
    levelNumber: 11,
    name: 'Safety Cross',
    coinReward: 450,
    lives: 5,
    rowsArt: const [
      '....###....',
      '....###....',
      '....###....',
      '....###....',
      '###########',
      '###########',
      '###########',
      '....###....',
      '....###....',
      '....###....',
      '....###....',
    ],
  ),
  PuzzleLevel(
    levelNumber: 12,
    name: 'Crane Signal',
    coinReward: 500,
    lives: 5,
    rowsArt: const [
      '.....#.....',
      '....###....',
      '...#####...',
      '..#######..',
      '.#########.',
      '###########',
      '....###....',
      '....###....',
      '....###....',
      '....###....',
      '....###....',
    ],
  ),
  PuzzleLevel(
    levelNumber: 13,
    name: 'Cut Diamond',
    coinReward: 550,
    lives: 5,
    rowsArt: const [
      '.....##.....',
      '....####....',
      '...######...',
      '..########..',
      '.##########.',
      '############',
      '############',
      '.##########.',
      '..########..',
      '...######...',
      '....####....',
      '.....##.....',
    ],
  ),
  PuzzleLevel(
    levelNumber: 14,
    name: 'City Heart',
    coinReward: 600,
    lives: 4,
    rowsArt: const [
      '...##..##...',
      '..########..',
      '.##########.',
      '.##########.',
      '.##########.',
      '..########..',
      '..########..',
      '...######...',
      '....####....',
      '.....##.....',
    ],
  ),
  PuzzleLevel(
    levelNumber: 15,
    name: 'Grand Tower',
    coinReward: 700,
    lives: 4,
    rowsArt: const [
      '.....###.....',
      '.....###.....',
      '....#####....',
      '....#####....',
      '...#######...',
      '...#######...',
      '..#########..',
      '..#########..',
      '.###########.',
      '.###########.',
      '#############',
      '#############',
      '#############',
    ],
  ),
];

PuzzleLevel puzzleLevelByNumber(int number) =>
    puzzleLevels.firstWhere((l) => l.levelNumber == number,
        orElse: () => puzzleLevels.first);
