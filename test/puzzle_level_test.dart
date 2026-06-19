import 'package:flutter_test/flutter_test.dart';
import 'package:tower_dash_bricks/game/battle_controller.dart';
import 'package:tower_dash_bricks/game/brick_unit.dart';
import 'package:tower_dash_bricks/game/campaign.dart';
import 'package:tower_dash_bricks/game/synergies.dart';
import 'package:tower_dash_bricks/game/unit_catalog.dart';
import 'package:tower_dash_bricks/game/unit_class.dart';

void main() {
  test('catalog has every class x rarity combo', () {
    expect(unitCatalog.length, UnitClass.values.length * Rarity.values.length);
    for (final def in unitCatalog) {
      expect(def.attackAt(1), greaterThan(0));
      expect(def.healthAt(1), greaterThan(0));
      expect(unitDefById(def.id), isNotNull);
    }
  });

  test('higher rarity and level scale stats up', () {
    final common = unitDef(UnitClass.warrior, Rarity.common);
    final legendary = unitDef(UnitClass.warrior, Rarity.legendary);
    expect(legendary.attackAt(1), greaterThan(common.attackAt(1)));
    expect(common.attackAt(5), greaterThan(common.attackAt(1)));
  });

  test('class synergy boosts the team', () {
    final units = [
      for (var i = 0; i < 3; i++)
        BrickUnit(def: unitDef(UnitClass.warrior, Rarity.common), level: 1),
    ];
    final baseAtk = units.first.atk;
    final bonuses = SynergyEngine.apply(units);
    expect(bonuses, isNotEmpty);
    expect(units.first.atk, greaterThan(baseAtk));
  });

  test('a battle always reaches a conclusion', () {
    final player = [
      BrickUnit(def: unitDef(UnitClass.tank, Rarity.rare), level: 3),
      BrickUnit(def: unitDef(UnitClass.warrior, Rarity.rare), level: 3),
      BrickUnit(def: unitDef(UnitClass.archer, Rarity.rare), level: 3),
    ];
    final enemy = [
      BrickUnit(def: unitDef(UnitClass.bomber, Rarity.common), level: 1),
      BrickUnit(def: unitDef(UnitClass.mage, Rarity.common), level: 1),
    ];
    final ctrl = BattleController(playerUnits: player, enemyUnits: enemy);
    ctrl.begin();
    var guard = 0;
    while (ctrl.isFighting && guard++ < 1000) {
      ctrl.step();
    }
    expect(ctrl.isOver, isTrue);
  });

  test('campaign exposes the expected number of waves', () {
    expect(totalWaves, chapters.fold<int>(0, (s, c) => s + c.waveCount));
    final first = campaignWave(1);
    expect(first.enemies, isNotEmpty);
    final boss = campaignWave(chapters.first.waveCount);
    expect(boss.isBoss, isTrue);
  });
}
