import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/brick_unit.dart';
import '../game/unit_catalog.dart';
import '../game/unit_class.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/pixel_button.dart';
import '../widgets/unit_card.dart';
import '../widgets/unit_sprite.dart';
import 'upgrade_screen.dart';

const int kMaxDeck = 8;

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChange);
  }

  @override
  void dispose() {
    progress.removeListener(_onChange);
    // Acknowledge level-up markers once the player has seen the collection.
    progress.markLevelUpsSeen();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<MapEntry<UnitDef, int>> get _owned {
    final owned = progress.ownedUnits;
    final out = <MapEntry<UnitDef, int>>[];
    for (final def in unitCatalog) {
      final level = owned[def.id];
      if (level != null) out.add(MapEntry(def, level));
    }
    // Strongest first.
    out.sort((a, b) => (b.key.powerScore * b.value)
        .compareTo(a.key.powerScore * a.value));
    return out;
  }

  Future<void> _toggleDeck(String id) async {
    final deck = List<String>.from(progress.deck);
    if (deck.contains(id)) {
      deck.remove(id);
      AudioService.instance.playSfx(Sfx.buttonClick);
      await progress.setDeck(deck);
    } else if (deck.length < kMaxDeck) {
      deck.add(id);
      AudioService.instance.playSfx(Sfx.buttonClick);
      await progress.setDeck(deck);
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.panelSolid,
          content: Text('Deck is full ($kMaxDeck max)',
              style: AppTextStyles.body()),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  void _openDetail(UnitDef def, int level) {
    AudioService.instance.playSfx(Sfx.buttonClick);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitDetailSheet(
        def: def,
        onToggleDeck: () => _toggleDeck(def.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = _owned;
    final deck = progress.deck;
    return Scaffold(
      body: BrickBackground(
        dim: 0.2,
        showGround: false,
        child: SafeArea(
          child: Column(
            children: [
              _Header(deckCount: deck.length),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: owned.length,
                  itemBuilder: (_, i) {
                    final def = owned[i].key;
                    final level = owned[i].value;
                    final inDeck = deck.contains(def.id);
                    final leveled = progress.isNewlyLeveled(def.id);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UnitCard(
                          def: def,
                          level: level,
                          selected: inDeck,
                          onTap: () => _openDetail(def, level),
                          badge: inDeck
                              ? Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.craneYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      size: 12, color: AppColors.textDark),
                                )
                              : null,
                        ),
                        if (leveled)
                          Positioned(
                            top: -4,
                            left: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.success
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_upward_rounded,
                                      size: 10, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text('LV UP',
                                      style: AppTextStyles.body(
                                          size: 9, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.deckCount});
  final int deckCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.instance.playSfx(Sfx.buttonClick);
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COLLECTION',
                    style: AppTextStyles.body(
                            size: 11, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 3)),
                Text('Your Bricks', style: AppTextStyles.title(size: 26)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.craneYellow.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dashboard_customize_rounded,
                    size: 16, color: AppColors.craneYellow),
                const SizedBox(width: 6),
                Text('Deck $deckCount/$kMaxDeck',
                    style: AppTextStyles.button(
                        size: 13, color: AppColors.craneYellow)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitDetailSheet extends StatefulWidget {
  const _UnitDetailSheet({required this.def, required this.onToggleDeck});
  final UnitDef def;
  final VoidCallback onToggleDeck;

  @override
  State<_UnitDetailSheet> createState() => _UnitDetailSheetState();
}

class _UnitDetailSheetState extends State<_UnitDetailSheet> {
  void _openUpgrade() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    Navigator.of(context).pop(); // close the sheet
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UpgradeScreen(def: widget.def)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final level = progress.unitLevel(def.id);
    final cost = def.upgradeCost(level);
    final inDeck = progress.deck.contains(def.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              UnitSprite(clazz: def.clazz, rarity: def.rarity, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name, style: AppTextStyles.title(size: 22)),
                    Row(
                      children: [
                        Text('${def.rarity.label} ',
                            style: AppTextStyles.body(
                                size: 12, color: def.rarity.color)),
                        for (var i = 0; i < def.rarity.stars; i++)
                          Icon(Icons.star_rounded,
                              size: 12, color: def.rarity.color),
                      ],
                    ),
                    Text('${def.clazz.label} · ${def.clazz.roleHint}',
                        style: AppTextStyles.body(
                            size: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(
                  icon: Icons.bolt_rounded,
                  label: 'Attack',
                  value: '${def.attackAt(level)}',
                  color: AppColors.accent),
              const SizedBox(width: 10),
              _StatBox(
                  icon: Icons.favorite_rounded,
                  label: 'Health',
                  value: '${def.healthAt(level)}',
                  color: AppColors.success),
              const SizedBox(width: 10),
              _StatBox(
                  icon: Icons.military_tech_rounded,
                  label: 'Level',
                  value: '$level',
                  color: AppColors.craneYellow),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: def.clazz.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: def.clazz.color.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: def.clazz.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(def.clazz.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ability · ${def.clazz.abilityName}',
                          style: AppTextStyles.button(size: 13)),
                      Text(def.clazz.roleHint,
                          style: AppTextStyles.body(
                              size: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PixelButton(
            label: 'Upgrade · $cost',
            icon: Icons.upgrade_rounded,
            width: double.infinity,
            onPressed: _openUpgrade,
          ),
          const SizedBox(height: 10),
          PixelButton(
            label: inDeck ? 'Remove from Deck' : 'Add to Deck',
            width: double.infinity,
            color: inDeck ? PixelButtonColor.danger : PixelButtonColor.secondary,
            onPressed: () {
              widget.onToggleDeck();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.score(size: 18, color: color)),
            Text(label,
                style:
                    AppTextStyles.body(size: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
