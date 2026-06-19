import 'package:flutter/foundation.dart';

import 'brick_unit.dart';
import 'synergies.dart';
import 'tower.dart';
import 'unit_class.dart';

enum BattlePhase { building, fighting, won, lost }

enum BattleActionType { attack, splash, heal }

/// Identifies one unit by side + stack index.
class UnitRef {
  const UnitRef(this.isPlayer, this.index);
  final bool isPlayer;
  final int index;
}

/// One discrete action in the auto-battle, consumed by the UI for animation,
/// VFX and SFX.
class BattleEvent {
  BattleEvent({
    required this.type,
    required this.attacker,
    required this.targets,
    required this.amount,
    required this.attackerClass,
    required this.deaths,
  });

  final BattleActionType type;
  final UnitRef attacker;
  final List<UnitRef> targets;

  /// Damage (for attack/splash) or HP healed (for heal), per target.
  final int amount;
  final UnitClass attackerClass;
  final List<UnitRef> deaths;
}

/// Turn-based auto-battler between two brick towers.
///
/// Sides alternate taking one unit action per [step]. The bottom-most living
/// unit always acts; targeting depends on the actor's class. The UI drives the
/// pace by calling [step] on a timer so each action can be animated.
class BattleController extends ChangeNotifier {
  BattleController({
    required List<BrickUnit> playerUnits,
    required List<BrickUnit> enemyUnits,
    this.maxReinforcements = 1,
  })  : player = Tower(playerUnits),
        enemy = Tower(enemyUnits);

  final Tower player;
  final Tower enemy;
  final int maxReinforcements;

  BattlePhase _phase = BattlePhase.building;
  bool _playerTurn = true;
  int _round = 0;
  int _reinforcementsUsed = 0;
  int _bossActions = 0;
  BattleEvent? _lastEvent;

  List<SynergyBonus> playerSynergies = const [];
  List<SynergyBonus> enemySynergies = const [];

  BattlePhase get phase => _phase;
  int get round => _round;
  BattleEvent? get lastEvent => _lastEvent;
  bool get isFighting => _phase == BattlePhase.fighting;
  bool get isOver => _phase == BattlePhase.won || _phase == BattlePhase.lost;
  bool get canReinforce =>
      _phase == BattlePhase.lost && _reinforcementsUsed < maxReinforcements;

  /// Lock in lineups, apply synergies and start the fight.
  void begin() {
    if (_phase != BattlePhase.building) return;
    playerSynergies = SynergyEngine.apply(player.units);
    enemySynergies = SynergyEngine.apply(enemy.units);
    _applyArmor(player.units);
    _applyArmor(enemy.units);
    _playerTurn = true;
    _phase = BattlePhase.fighting;
    notifyListeners();
  }

  /// Grant front-line classes their passive starting shield.
  void _applyArmor(List<BrickUnit> units) {
    for (final u in units) {
      if (u.isBoss) continue;
      final frac = u.clazz.armorFraction;
      if (frac > 0) u.shield += (u.maxHp * frac).round();
    }
  }

  /// Advance the battle by one unit action.
  BattleEvent? step() {
    if (_phase != BattlePhase.fighting) return null;

    if (!player.isAlive || !enemy.isAlive) {
      _finish();
      return null;
    }

    final attackerTower = _playerTurn ? player : enemy;
    final defenderTower = _playerTurn ? enemy : player;
    final attackerIdx = attackerTower.firstAliveIndex();
    if (attackerIdx == -1) {
      _finish();
      return null;
    }

    final event = _act(
      attackerTower.units[attackerIdx],
      attackerIdx,
      attackerTower,
      defenderTower,
      _playerTurn,
    );
    _lastEvent = event;
    _round++;

    if (!player.isAlive || !enemy.isAlive) {
      _finish();
    } else {
      _playerTurn = !_playerTurn;
    }
    notifyListeners();
    return event;
  }

  BattleEvent _act(
    BrickUnit attacker,
    int attackerIdx,
    Tower attackerTower,
    Tower defenderTower,
    bool isPlayer,
  ) {
    final atkRef = UnitRef(isPlayer, attackerIdx);
    final deaths = <UnitRef>[];

    if (attacker.isBoss) {
      return _bossAct(attacker, atkRef, defenderTower, isPlayer, deaths);
    }

    switch (attacker.def.targetMode) {
      case TargetMode.woundedAlly:
        final allyIdx = attackerTower.mostWoundedIndex();
        if (allyIdx != -1 && allyIdx != attackerIdx) {
          final amount = (attacker.atk * 1.5).round();
          attackerTower.units[allyIdx].heal(amount);
          return BattleEvent(
            type: BattleActionType.heal,
            attacker: atkRef,
            targets: [UnitRef(isPlayer, allyIdx)],
            amount: amount,
            attackerClass: attacker.clazz,
            deaths: const [],
          );
        }
        // No one to heal — chip the front enemy instead.
        final t = defenderTower.firstAliveIndex();
        final dmg = (attacker.atk * 0.6).round();
        defenderTower.units[t].takeDamage(dmg);
        if (!defenderTower.units[t].isAlive) deaths.add(UnitRef(!isPlayer, t));
        return BattleEvent(
          type: BattleActionType.attack,
          attacker: atkRef,
          targets: [UnitRef(!isPlayer, t)],
          amount: dmg,
          attackerClass: attacker.clazz,
          deaths: deaths,
        );

      case TargetMode.splashFront:
        final idxs = defenderTower.frontTwoAliveIndices();
        final dmg = (attacker.atk * 0.75).round();
        final targets = <UnitRef>[];
        for (final i in idxs) {
          defenderTower.units[i].takeDamage(dmg);
          targets.add(UnitRef(!isPlayer, i));
          if (!defenderTower.units[i].isAlive) deaths.add(UnitRef(!isPlayer, i));
        }
        return BattleEvent(
          type: BattleActionType.splash,
          attacker: atkRef,
          targets: targets,
          amount: dmg,
          attackerClass: attacker.clazz,
          deaths: deaths,
        );

      case TargetMode.lowestHp:
        final t = defenderTower.lowestHpIndex();
        final dmg = attacker.atk;
        defenderTower.units[t].takeDamage(dmg);
        if (!defenderTower.units[t].isAlive) deaths.add(UnitRef(!isPlayer, t));
        return BattleEvent(
          type: BattleActionType.attack,
          attacker: atkRef,
          targets: [UnitRef(!isPlayer, t)],
          amount: dmg,
          attackerClass: attacker.clazz,
          deaths: deaths,
        );

      case TargetMode.front:
        final t = defenderTower.firstAliveIndex();
        final dmg = attacker.atk;
        defenderTower.units[t].takeDamage(dmg);
        if (!defenderTower.units[t].isAlive) deaths.add(UnitRef(!isPlayer, t));
        return BattleEvent(
          type: BattleActionType.attack,
          attacker: atkRef,
          targets: [UnitRef(!isPlayer, t)],
          amount: dmg,
          attackerClass: attacker.clazz,
          deaths: deaths,
        );
    }
  }

  /// Solo-boss turn. Every third action unleashes the boss's signature ability;
  /// otherwise it lands a heavy front-line smash.
  BattleEvent _bossAct(
    BrickUnit boss,
    UnitRef atkRef,
    Tower defenderTower,
    bool isPlayer,
    List<UnitRef> deaths,
  ) {
    _bossActions++;
    final useAbility = _bossActions % 3 == 0;

    if (useAbility) {
      switch (boss.bossAbility!) {
        case BossAbility.shockwave:
          final dmg = (boss.atk * 0.55).round();
          final targets = <UnitRef>[];
          for (var i = 0; i < defenderTower.units.length; i++) {
            final u = defenderTower.units[i];
            if (!u.isAlive) continue;
            u.takeDamage(dmg);
            targets.add(UnitRef(!isPlayer, i));
            if (!u.isAlive) deaths.add(UnitRef(!isPlayer, i));
          }
          return BattleEvent(
            type: BattleActionType.splash,
            attacker: atkRef,
            targets: targets,
            amount: dmg,
            attackerClass: boss.clazz,
            deaths: deaths,
          );

        case BossAbility.wreckingBall:
          final idxs = defenderTower.frontTwoAliveIndices();
          final dmg = (boss.atk * 1.1).round();
          final targets = <UnitRef>[];
          for (final i in idxs) {
            defenderTower.units[i].takeDamage(dmg);
            targets.add(UnitRef(!isPlayer, i));
            if (!defenderTower.units[i].isAlive) {
              deaths.add(UnitRef(!isPlayer, i));
            }
          }
          return BattleEvent(
            type: BattleActionType.splash,
            attacker: atkRef,
            targets: targets,
            amount: dmg,
            attackerClass: boss.clazz,
            deaths: deaths,
          );

        case BossAbility.siphon:
          final t = defenderTower.lowestHpIndex();
          final dmg = (boss.atk * 1.3).round();
          final dealt = defenderTower.units[t].takeDamage(dmg);
          boss.heal((dealt * 0.8).round());
          if (!defenderTower.units[t].isAlive) deaths.add(UnitRef(!isPlayer, t));
          return BattleEvent(
            type: BattleActionType.attack,
            attacker: atkRef,
            targets: [UnitRef(!isPlayer, t)],
            amount: dmg,
            attackerClass: boss.clazz,
            deaths: deaths,
          );
      }
    }

    // Normal heavy smash on the front unit.
    final t = defenderTower.firstAliveIndex();
    final dmg = boss.atk;
    defenderTower.units[t].takeDamage(dmg);
    if (!defenderTower.units[t].isAlive) deaths.add(UnitRef(!isPlayer, t));
    return BattleEvent(
      type: BattleActionType.attack,
      attacker: atkRef,
      targets: [UnitRef(!isPlayer, t)],
      amount: dmg,
      attackerClass: boss.clazz,
      deaths: deaths,
    );
  }

  void _finish() {
    _phase = player.isAlive ? BattlePhase.won : BattlePhase.lost;
  }

  /// Spend a reinforcement after losing: revive/heal the player's tower and
  /// resume the fight. Returns false if not allowed.
  bool reinforce() {
    if (!canReinforce) return false;
    _reinforcementsUsed++;
    for (final u in player.units) {
      if (!u.isAlive) {
        u.hp = (u.maxHp * 0.45).round().clamp(1, u.maxHp);
      } else {
        u.hp = (u.hp + (u.maxHp * 0.3)).round().clamp(0, u.maxHp);
      }
    }
    _playerTurn = true;
    _phase = BattlePhase.fighting;
    notifyListeners();
    return true;
  }
}
