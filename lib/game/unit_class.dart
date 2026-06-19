import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/tdb_assets.dart';

/// The six brick-unit classes. Class is the unit's identity: it fixes the
/// sprite, the suit color (used for synergies) and the combat role.
enum UnitClass { tank, warrior, archer, mage, healer, bomber, golem, sniper }

/// How a unit picks its target during the auto-battle.
enum TargetMode {
  /// First (bottom-most) living enemy.
  front,

  /// Living enemy with the lowest current HP.
  lowestHp,

  /// The two bottom-most living enemies (AoE).
  splashFront,

  /// The most wounded living ally (negative "damage" = heal).
  woundedAlly,
}

extension UnitClassInfo on UnitClass {
  String get id => name;

  String get label {
    switch (this) {
      case UnitClass.tank:
        return 'Tank';
      case UnitClass.warrior:
        return 'Warrior';
      case UnitClass.archer:
        return 'Archer';
      case UnitClass.mage:
        return 'Mage';
      case UnitClass.healer:
        return 'Healer';
      case UnitClass.bomber:
        return 'Bomber';
      case UnitClass.golem:
        return 'Golem';
      case UnitClass.sniper:
        return 'Sniper';
    }
  }

  String get asset {
    switch (this) {
      case UnitClass.tank:
        return TdbAssets.unitTank;
      case UnitClass.warrior:
        return TdbAssets.unitWarrior;
      case UnitClass.archer:
        return TdbAssets.unitArcher;
      case UnitClass.mage:
        return TdbAssets.unitMage;
      case UnitClass.healer:
        return TdbAssets.unitHealer;
      case UnitClass.bomber:
        return TdbAssets.unitBomber;
      case UnitClass.golem:
        return TdbAssets.unitGolem;
      case UnitClass.sniper:
        return TdbAssets.unitSniper;
    }
  }

  Color get color {
    switch (this) {
      case UnitClass.tank:
        return AppColors.tank;
      case UnitClass.warrior:
        return AppColors.warrior;
      case UnitClass.archer:
        return AppColors.archer;
      case UnitClass.mage:
        return AppColors.mage;
      case UnitClass.healer:
        return AppColors.healer;
      case UnitClass.bomber:
        return AppColors.bomber;
      case UnitClass.golem:
        return AppColors.golem;
      case UnitClass.sniper:
        return AppColors.sniper;
    }
  }

  TargetMode get targetMode {
    switch (this) {
      case UnitClass.tank:
      case UnitClass.warrior:
        return TargetMode.front;
      case UnitClass.archer:
      case UnitClass.mage:
        return TargetMode.lowestHp;
      case UnitClass.bomber:
        return TargetMode.splashFront;
      case UnitClass.healer:
        return TargetMode.woundedAlly;
      case UnitClass.golem:
        return TargetMode.front;
      case UnitClass.sniper:
        return TargetMode.lowestHp;
    }
  }

  /// Relative stat weighting: (attack factor, health factor).
  /// Tanks are tanky, archers/mages hit hard but fragile, etc.
  (double atk, double hp) get statBias {
    switch (this) {
      case UnitClass.tank:
        return (0.55, 1.8);
      case UnitClass.warrior:
        return (1.05, 1.15);
      case UnitClass.archer:
        return (1.25, 0.8);
      case UnitClass.mage:
        return (1.35, 0.75);
      case UnitClass.healer:
        return (0.7, 0.95);
      case UnitClass.bomber:
        return (1.1, 0.85);
      case UnitClass.golem:
        return (0.95, 1.55);
      case UnitClass.sniper:
        return (1.45, 0.7);
    }
  }

  String get roleHint {
    switch (this) {
      case UnitClass.tank:
        return 'Soaks damage up front';
      case UnitClass.warrior:
        return 'Balanced front-line bruiser';
      case UnitClass.archer:
        return 'Picks off the weakest foe';
      case UnitClass.mage:
        return 'High burst on low-HP foes';
      case UnitClass.healer:
        return 'Heals the most wounded ally';
      case UnitClass.bomber:
        return 'Splash damage to two foes';
      case UnitClass.golem:
        return 'Unbreakable front-line titan';
      case UnitClass.sniper:
        return 'Deletes the weakest foe';
    }
  }

  /// Short name of the unit's signature passive, shown with [icon] as a badge
  /// so each class reads as mechanically distinct at a glance.
  String get abilityName {
    switch (this) {
      case UnitClass.tank:
        return 'Armor';
      case UnitClass.warrior:
        return 'Bruiser';
      case UnitClass.archer:
        return 'Snipe Weak';
      case UnitClass.mage:
        return 'Arcane Burst';
      case UnitClass.healer:
        return 'Regen';
      case UnitClass.bomber:
        return 'Splash';
      case UnitClass.golem:
        return 'Bedrock';
      case UnitClass.sniper:
        return 'Headshot';
    }
  }

  /// Fraction of max HP granted as a starting shield (passive armor). Front-line
  /// defenders soak far more punishment than everyone else.
  double get armorFraction {
    switch (this) {
      case UnitClass.golem:
        return 0.55;
      case UnitClass.tank:
        return 0.35;
      default:
        return 0.0;
    }
  }

  IconData get icon {
    switch (this) {
      case UnitClass.tank:
        return Icons.shield_rounded;
      case UnitClass.warrior:
        return Icons.sports_kabaddi_rounded;
      case UnitClass.archer:
        return Icons.gps_fixed_rounded;
      case UnitClass.mage:
        return Icons.auto_awesome_rounded;
      case UnitClass.healer:
        return Icons.healing_rounded;
      case UnitClass.bomber:
        return Icons.local_fire_department_rounded;
      case UnitClass.golem:
        return Icons.fitness_center_rounded;
      case UnitClass.sniper:
        return Icons.center_focus_strong_rounded;
    }
  }
}

/// A solo campaign boss's signature attack. Each behaves differently so the
/// final wave of every chapter feels like a distinct showdown.
enum BossAbility { shockwave, wreckingBall, siphon }

extension BossAbilityInfo on BossAbility {
  String get label {
    switch (this) {
      case BossAbility.shockwave:
        return 'Shockwave';
      case BossAbility.wreckingBall:
        return 'Wrecking Ball';
      case BossAbility.siphon:
        return 'Siphon';
    }
  }

  String get description {
    switch (this) {
      case BossAbility.shockwave:
        return 'Slams every unit in your tower';
      case BossAbility.wreckingBall:
        return 'Crushes your two front units';
      case BossAbility.siphon:
        return 'Drains a unit and heals itself';
    }
  }

  IconData get icon {
    switch (this) {
      case BossAbility.shockwave:
        return Icons.bolt_rounded;
      case BossAbility.wreckingBall:
        return Icons.sports_baseball_rounded;
      case BossAbility.siphon:
        return Icons.bloodtype_rounded;
    }
  }
}

/// Rarity tiers — each is a distinct collectible variant of a class that
/// shares the sprite but scales stats and uses a colored frame.
enum Rarity { common, rare, epic, legendary }

extension RarityInfo on Rarity {
  String get id => name;

  String get label {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.rare:
        return 'Rare';
      case Rarity.epic:
        return 'Epic';
      case Rarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return AppColors.rarityCommon;
      case Rarity.rare:
        return AppColors.rarityRare;
      case Rarity.epic:
        return AppColors.rarityEpic;
      case Rarity.legendary:
        return AppColors.rarityLegendary;
    }
  }

  /// Stat multiplier applied on top of the class base stats.
  double get statMult {
    switch (this) {
      case Rarity.common:
        return 1.0;
      case Rarity.rare:
        return 1.35;
      case Rarity.epic:
        return 1.8;
      case Rarity.legendary:
        return 2.4;
    }
  }

  int get stars {
    switch (this) {
      case Rarity.common:
        return 1;
      case Rarity.rare:
        return 2;
      case Rarity.epic:
        return 3;
      case Rarity.legendary:
        return 4;
    }
  }

  /// Relative pull weight for gacha (higher = more common).
  int get gachaWeight {
    switch (this) {
      case Rarity.common:
        return 60;
      case Rarity.rare:
        return 28;
      case Rarity.epic:
        return 10;
      case Rarity.legendary:
        return 2;
    }
  }
}
