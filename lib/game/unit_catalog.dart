import 'brick_unit.dart';
import 'unit_class.dart';

/// Themed display names per class + rarity (6 classes x 4 rarities = 24 units).
const Map<UnitClass, Map<Rarity, String>> _names = {
  UnitClass.tank: {
    Rarity.common: 'Concrete Block',
    Rarity.rare: 'Steel Bulwark',
    Rarity.epic: 'Titan Wall',
    Rarity.legendary: 'Fortress Prime',
  },
  UnitClass.warrior: {
    Rarity.common: 'Brick Brawler',
    Rarity.rare: 'Iron Striker',
    Rarity.epic: 'Crimson Champion',
    Rarity.legendary: 'Warlord Magnus',
  },
  UnitClass.archer: {
    Rarity.common: 'Sling Recruit',
    Rarity.rare: 'Bolt Marksman',
    Rarity.epic: 'Eagle Sniper',
    Rarity.legendary: 'Storm Arrow',
  },
  UnitClass.mage: {
    Rarity.common: 'Spark Apprentice',
    Rarity.rare: 'Rune Caster',
    Rarity.epic: 'Arcane Master',
    Rarity.legendary: 'Voidweaver',
  },
  UnitClass.healer: {
    Rarity.common: 'Field Medic',
    Rarity.rare: 'Mender Brick',
    Rarity.epic: 'Lifebinder',
    Rarity.legendary: 'Saint Aurora',
  },
  UnitClass.bomber: {
    Rarity.common: 'Fuse Lobber',
    Rarity.rare: 'Blast Sapper',
    Rarity.epic: 'Demolition Ace',
    Rarity.legendary: 'Inferno King',
  },
  UnitClass.golem: {
    Rarity.common: 'Rubble Golem',
    Rarity.rare: 'Granite Guardian',
    Rarity.epic: 'Mosswall Colossus',
    Rarity.legendary: 'Bedrock Titan',
  },
  UnitClass.sniper: {
    Rarity.common: 'Bolt Scout',
    Rarity.rare: 'Keen Marksman',
    Rarity.epic: 'Phantom Shot',
    Rarity.legendary: 'Deadeye Legend',
  },
};

/// Every collectible unit, ordered by class then rarity.
final List<UnitDef> unitCatalog = [
  for (final clazz in UnitClass.values)
    for (final rarity in Rarity.values)
      UnitDef(
        clazz: clazz,
        rarity: rarity,
        name: _names[clazz]![rarity]!,
      ),
];

final Map<String, UnitDef> _byId = {
  for (final d in unitCatalog) d.id: d,
};

UnitDef? unitDefById(String id) => _byId[id];

UnitDef unitDef(UnitClass clazz, Rarity rarity) =>
    _byId['${clazz.id}_${rarity.id}']!;

/// Units the player owns when starting fresh: a Warrior + Archer duo. The rest
/// are unlocked by progressing through the campaign and opening crates.
List<String> get starterUnitIds => [
      unitDef(UnitClass.warrior, Rarity.common).id,
      unitDef(UnitClass.archer, Rarity.common).id,
    ];
