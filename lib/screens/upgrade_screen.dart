import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/brick_unit.dart';
import '../game/unit_class.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/pixel_button.dart';
import '../widgets/unit_sprite.dart';

enum _UpgradePhase { idle, playing, success, fail }

/// Upgrade mini-game (the classic Tower Dash Bricks crane builder): a crane
/// carries a building floor that swings left–right; tap DROP when it lines up
/// over the tower to stack it. Stack [_required] floors to finish the building
/// and level the unit up. Coins are only spent on a completed building.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key, required this.def});
  final UnitDef def;

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen>
    with SingleTickerProviderStateMixin {
  // Slow swing so the timing is comfortable and beatable.
  late final AnimationController _mover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1950),
  );

  _UpgradePhase _phase = _UpgradePhase.idle;
  int _floors = 0;
  int _newLevel = 0;
  final math.Random _rng = math.Random();
  late List<int> _floorSprites;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _floorSprites =
        List.generate(_required, (_) => _rng.nextInt(TdbAssets.buildingFloorCount));
    progress.addListener(_onChange);
  }

  @override
  void dispose() {
    progress.removeListener(_onChange);
    _mover.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  int get _level => progress.unitLevel(widget.def.id);
  int get _cost => widget.def.upgradeCost(_level);
  bool get _canAfford => progress.coins >= _cost;

  // The building gets taller the higher the unit's level — later upgrades
  // demand a bigger tower.
  int get _required => (3 + _level ~/ 2).clamp(3, 8);

  // The drop zone shrinks a little as the building grows taller, but stays
  // generous so the level is always beatable.
  double get _tolerance => (0.24 - 0.025 * _floors).clamp(0.13, 0.24);

  /// Crane trolley position in 0..1 (triangle wave from the controller).
  double get _pos {
    final t = _mover.value;
    return t < 0.5 ? t * 2 : 2 - t * 2;
  }

  void _start() {
    if (!_canAfford) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _phase = _UpgradePhase.playing;
      _floors = 0;
      _floorSprites = List.generate(
          _required, (_) => _rng.nextInt(TdbAssets.buildingFloorCount));
    });
    _mover.repeat();
  }

  void _drop() {
    if (_phase != _UpgradePhase.playing) return;
    final dist = (_pos - 0.5).abs();
    if (dist <= _tolerance) {
      AudioService.instance.playSfx(Sfx.upgradeLand);
      AudioService.instance.vibrate();
      setState(() => _floors++);
      if (_floors >= _required) {
        _succeed();
      }
    } else {
      AudioService.instance.playSfx(Sfx.upgradeMiss);
      AudioService.instance.vibrate(heavy: true);
      _mover.stop();
      setState(() => _phase = _UpgradePhase.fail);
    }
  }

  Future<void> _succeed() async {
    _mover.stop();
    final ok = await progress.upgradeUnit(widget.def.id);
    AudioService.instance.playSfx(Sfx.levelUp);
    setState(() {
      _phase = ok ? _UpgradePhase.success : _UpgradePhase.fail;
      _newLevel = _level;
    });
  }

  void _reset() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _phase = _UpgradePhase.idle;
      _floors = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return Scaffold(
      body: BrickBackground(
        skyAsset: TdbAssets.sky2,
        showGround: false,
        dim: 0.12,
        child: SafeArea(
          child: Column(
            children: [
              _Header(name: def.name, coins: progress.coins),
              _UnitBanner(def: def, level: _level),
              Expanded(child: _playArea()),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playArea() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // Reserve headroom for the crane, then size floors small enough that
        // the whole building (all floors + the shop base) fits comfortably.
        const craneSpace = 96.0;
        final avail = c.maxHeight - craneSpace;
        var floorH = avail / (_required + 1.7);
        var floorW = floorH / 0.62;
        final maxW = w * 0.34;
        if (floorW > maxW) {
          floorW = maxW;
          floorH = floorW * 0.62;
        }
        floorW = floorW.clamp(60.0, 118.0).toDouble();
        floorH = floorH.clamp(38.0, 74.0).toDouble();
        final range = w - floorW;
        final bandW = (_tolerance * 2 * range).clamp(44.0, range);

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Drop-zone band (centered over the tower).
            Positioned(
              bottom: 0,
              top: 70,
              child: Container(
                width: bandW,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.symmetric(
                    vertical: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.55),
                        width: 1.4),
                  ),
                ),
              ),
            ),
            // The building: shop base + stacked floors, grounded at the bottom.
            Positioned(
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = _floors - 1; i >= 0; i--)
                    Image.asset(
                      TdbAssets.buildingFloor(_floorSprites[i]),
                      width: floorW,
                      height: floorH,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  Image.asset(
                    TdbAssets.shopBase,
                    width: floorW * 1.04,
                    fit: BoxFit.fitWidth,
                    gaplessPlayback: true,
                  ),
                ],
              ),
            ),
            // The crane trolley carrying the next floor across the top.
            if (_phase == _UpgradePhase.playing)
              AnimatedBuilder(
                animation: _mover,
                builder: (_, _) {
                  return Positioned(
                    top: 0,
                    left: _pos * range,
                    child: SizedBox(
                      width: floorW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(TdbAssets.crane,
                              width: (floorW * 0.7).clamp(58.0, 86.0),
                              gaplessPlayback: true),
                          Container(
                              width: 2.5,
                              height: 8,
                              color: const Color(0xFF3A4660)),
                          Image.asset(TdbAssets.craneHook,
                              width: 20, gaplessPlayback: true),
                          Image.asset(
                            TdbAssets.buildingFloor(
                                _floorSprites[_floors.clamp(0, _required - 1)]),
                            width: floorW,
                            height: floorH,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Positioned(
                top: 0,
                child: Image.asset(TdbAssets.crane,
                    width: (floorW * 0.78).clamp(64.0, 92.0),
                    gaplessPlayback: true),
              ),
            // Floor progress dots.
            Positioned(
              top: 6,
              right: 8,
              child: Column(
                children: [
                  for (var i = _required - 1; i >= 0; i--)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Icon(
                        i < _floors
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: i < _floors
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: switch (_phase) {
        _UpgradePhase.idle => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Build a $_required-floor tower! Tap DROP when the crane lines '
                'up the floor with the building — the drop zone shrinks as you '
                'go higher.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              PixelButton(
                label: _canAfford ? 'Upgrade · $_cost' : 'Need $_cost coins',
                icon: Icons.upgrade_rounded,
                width: double.infinity,
                height: 58,
                onPressed: _canAfford ? _start : null,
              ),
            ],
          ),
        _UpgradePhase.playing => PixelButton(
            label: 'DROP  ($_floors/$_required)',
            icon: Icons.south_rounded,
            width: double.infinity,
            height: 64,
            onPressed: _drop,
          ),
        _UpgradePhase.success => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UpgradeResultPanel(def: widget.def, newLevel: _newLevel),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'Again',
                      color: PixelButtonColor.secondary,
                      width: double.infinity,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PixelButton(
                      label: 'Done',
                      width: double.infinity,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        _UpgradePhase.fail => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultBanner(
                icon: Icons.heart_broken_rounded,
                color: AppColors.danger,
                title: 'Floor Missed!',
                subtitle: 'No coins spent.',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'Leave',
                      color: PixelButtonColor.secondary,
                      width: double.infinity,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PixelButton(
                      label: 'Try Again',
                      width: double.infinity,
                      onPressed: _reset,
                    ),
                  ),
                ],
              ),
            ],
          ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.coins});
  final String name;
  final int coins;

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
                Text('UPGRADE',
                    style: AppTextStyles.body(
                            size: 11, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 3)),
                Text(name, style: AppTextStyles.title(size: 22)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_rounded,
                    color: AppColors.neonGold, size: 18),
                const SizedBox(width: 5),
                Text('$coins',
                    style: AppTextStyles.button(
                        size: 14, color: AppColors.neonGold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebration panel shown after a successful upgrade: the unit plus its
/// level, attack and health gains, so the progress is clearly visible.
class _UpgradeResultPanel extends StatelessWidget {
  const _UpgradeResultPanel({required this.def, required this.newLevel});
  final UnitDef def;
  final int newLevel;

  @override
  Widget build(BuildContext context) {
    final old = newLevel - 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success, width: 1.8),
        boxShadow: [
          BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 22),
              const SizedBox(width: 8),
              Text('Upgrade Complete!',
                  style: AppTextStyles.title(size: 18, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: def.rarity.color, width: 1.5),
                ),
                child: UnitSprite(clazz: def.clazz, rarity: def.rarity, size: 52),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name, style: AppTextStyles.button(size: 15)),
                    const SizedBox(height: 6),
                    _DeltaRow(
                      icon: Icons.military_tech_rounded,
                      color: AppColors.craneYellow,
                      label: 'Level',
                      from: '$old',
                      to: '$newLevel',
                    ),
                    _DeltaRow(
                      icon: Icons.bolt_rounded,
                      color: AppColors.accent,
                      label: 'ATK',
                      from: '${def.attackAt(old)}',
                      to: '${def.attackAt(newLevel)}',
                    ),
                    _DeltaRow(
                      icon: Icons.favorite_rounded,
                      color: AppColors.success,
                      label: 'HP',
                      from: '${def.healthAt(old)}',
                      to: '${def.healthAt(newLevel)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.from,
    required this.to,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: Text(label,
                style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
          ),
          Text(from,
              style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
          Icon(Icons.arrow_right_alt_rounded, size: 16, color: color),
          Text(to, style: AppTextStyles.button(size: 13, color: color)),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title(size: 18, color: color)),
                Text(subtitle,
                    style: AppTextStyles.body(
                        size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.def, required this.level});
  final UnitDef def;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: def.rarity.color, width: 1.5),
      ),
      child: Row(
        children: [
          UnitSprite(clazz: def.clazz, rarity: def.rarity, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name, style: AppTextStyles.button(size: 16)),
                Text('Level $level  →  ${level + 1}',
                    style: AppTextStyles.body(
                        size: 13, color: AppColors.craneYellow)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ATK ${def.attackAt(level)} → ${def.attackAt(level + 1)}',
                  style: AppTextStyles.body(size: 11, color: AppColors.accent)),
              Text('HP ${def.healthAt(level)} → ${def.healthAt(level + 1)}',
                  style: AppTextStyles.body(size: 11, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}
