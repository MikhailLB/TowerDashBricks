import 'brick_unit.dart';
import 'unit_class.dart';

/// A single active color/class synergy with its team-wide effect.
class SynergyBonus {
  const SynergyBonus({
    required this.clazz,
    required this.count,
    required this.tier,
    required this.description,
  });

  final UnitClass clazz;
  final int count;

  /// 1 = 3+ units, 2 = 5+ units.
  final int tier;
  final String description;
}

/// Computes and applies class synergies to a tower's units.
///
/// Stacking 3+ units of the same class triggers a team-wide buff; 5+ makes it
/// stronger. Effects from multiple classes stack.
class SynergyEngine {
  static const int _tier1 = 3;
  static const int _tier2 = 5;

  static Map<UnitClass, int> _counts(List<BrickUnit> units) {
    final counts = <UnitClass, int>{};
    for (final u in units) {
      counts[u.clazz] = (counts[u.clazz] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the active synergies for display (does not mutate units).
  static List<SynergyBonus> compute(List<BrickUnit> units) {
    final counts = _counts(units);
    final out = <SynergyBonus>[];
    counts.forEach((clazz, count) {
      if (count < _tier1) return;
      final tier = count >= _tier2 ? 2 : 1;
      out.add(SynergyBonus(
        clazz: clazz,
        count: count,
        tier: tier,
        description: _describe(clazz, tier),
      ));
    });
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  /// Applies all active synergies by mutating unit stats / shields in place.
  static List<SynergyBonus> apply(List<BrickUnit> units) {
    final bonuses = compute(units);
    for (final b in bonuses) {
      final atkMul = _atkMultiplier(b.clazz, b.tier);
      final hpMul = _hpMultiplier(b.clazz, b.tier);
      final shieldFrac = _shieldFraction(b.clazz, b.tier);
      for (final u in units) {
        if (atkMul != 1.0) u.atk = (u.atk * atkMul).round();
        if (hpMul != 1.0) {
          u.maxHp = (u.maxHp * hpMul).round();
          u.hp = (u.hp * hpMul).round();
        }
        if (shieldFrac > 0) u.shield += (u.maxHp * shieldFrac).round();
      }
    }
    return bonuses;
  }

  static double _atkMultiplier(UnitClass clazz, int tier) {
    switch (clazz) {
      case UnitClass.warrior:
        return tier == 2 ? 1.40 : 1.22;
      case UnitClass.archer:
        return tier == 2 ? 1.30 : 1.16;
      case UnitClass.mage:
        return tier == 2 ? 1.34 : 1.18;
      case UnitClass.bomber:
        return tier == 2 ? 1.32 : 1.18;
      case UnitClass.sniper:
        return tier == 2 ? 1.38 : 1.20;
      case UnitClass.golem:
        return tier == 2 ? 1.18 : 1.10;
      case UnitClass.tank:
      case UnitClass.healer:
        return 1.0;
    }
  }

  static double _hpMultiplier(UnitClass clazz, int tier) {
    switch (clazz) {
      case UnitClass.tank:
        return tier == 2 ? 1.40 : 1.22;
      case UnitClass.golem:
        return tier == 2 ? 1.32 : 1.18;
      case UnitClass.healer:
        return tier == 2 ? 1.25 : 1.12;
      default:
        return 1.0;
    }
  }

  static double _shieldFraction(UnitClass clazz, int tier) {
    if (clazz == UnitClass.healer) return tier == 2 ? 0.22 : 0.14;
    return 0;
  }

  static String _describe(UnitClass clazz, int tier) {
    final t = tier == 2 ? ' (max)' : '';
    switch (clazz) {
      case UnitClass.tank:
        return 'Bulwark$t: +HP to all allies';
      case UnitClass.warrior:
        return 'Onslaught$t: +ATK to all allies';
      case UnitClass.archer:
        return 'Volley$t: +ATK to all allies';
      case UnitClass.mage:
        return 'Resonance$t: +ATK to all allies';
      case UnitClass.healer:
        return 'Sanctuary$t: shields all allies';
      case UnitClass.bomber:
        return 'Demolition$t: +ATK to all allies';
      case UnitClass.golem:
        return 'Bedrock$t: +HP & +ATK to all allies';
      case UnitClass.sniper:
        return 'Deadeye$t: +ATK to all allies';
    }
  }
}
