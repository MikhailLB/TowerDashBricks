import 'brick_unit.dart';

/// An ordered stack of brick units. Index 0 is the bottom of the tower
/// (the front line); higher indices are stacked on top.
class Tower {
  Tower(this.units);

  final List<BrickUnit> units;

  bool get isAlive => units.any((u) => u.isAlive);
  int get aliveCount => units.where((u) => u.isAlive).length;

  /// Bottom-most living unit (the front line).
  int firstAliveIndex() {
    for (var i = 0; i < units.length; i++) {
      if (units[i].isAlive) return i;
    }
    return -1;
  }

  /// Living enemy with the lowest current HP (ties: closest to front).
  int lowestHpIndex() {
    var best = -1;
    var bestHp = 1 << 30;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (u.isAlive && u.hp < bestHp) {
        bestHp = u.hp;
        best = i;
      }
    }
    return best;
  }

  /// The two bottom-most living units (for splash attacks).
  List<int> frontTwoAliveIndices() {
    final out = <int>[];
    for (var i = 0; i < units.length && out.length < 2; i++) {
      if (units[i].isAlive) out.add(i);
    }
    return out;
  }

  /// Most-wounded living ally (largest missing HP). Returns -1 if all full.
  int mostWoundedIndex() {
    var best = -1;
    var bestMissing = 0;
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      if (!u.isAlive) continue;
      final missing = u.maxHp - u.hp;
      if (missing > bestMissing) {
        bestMissing = missing;
        best = i;
      }
    }
    return best;
  }

  int get totalPower {
    var sum = 0;
    for (final u in units) {
      sum += u.atk + (u.maxHp ~/ 3);
    }
    return sum;
  }
}
