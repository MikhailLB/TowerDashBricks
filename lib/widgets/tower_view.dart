import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/brick_unit.dart';
import '../game/tower.dart';
import '../game/unit_class.dart';
import 'unit_sprite.dart';

/// Renders one tower as a vertical stack of "brick cells". Index 0 (the front
/// line) sits at the bottom, resting on the base plate drawn by the battle
/// screen. Player towers are tinted green, enemy towers red.
class TowerView extends StatelessWidget {
  const TowerView({
    super.key,
    required this.tower,
    required this.isEnemy,
    required this.tileKeys,
    required this.tileSize,
    this.activeIndex,
    this.hitIndices = const {},
  });

  final Tower tower;
  final bool isEnemy;
  final List<GlobalKey> tileKeys;
  final double tileSize;
  final int? activeIndex;
  final Set<int> hitIndices;

  @override
  Widget build(BuildContext context) {
    final sideColor = isEnemy ? AppColors.danger : AppColors.success;

    // Solo boss: render one oversized, menacing figure instead of a stack.
    if (tower.units.length == 1 && tower.units.first.isBoss) {
      return Padding(
        key: tileKeys[0],
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _BossCell(
          unit: tower.units.first,
          isEnemy: isEnemy,
          size: tileSize,
          active: activeIndex == 0,
          hit: hitIndices.contains(0),
        ),
      );
    }

    final indices = List<int>.generate(tower.units.length, (i) => i);
    final ordered = indices.reversed.toList(); // top of column first

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final i in ordered)
          Padding(
            key: tileKeys[i],
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _UnitCell(
              unit: tower.units[i],
              isEnemy: isEnemy,
              sideColor: sideColor,
              size: tileSize,
              active: activeIndex == i,
              hit: hitIndices.contains(i),
            ),
          ),
      ],
    );
  }
}

class _UnitCell extends StatelessWidget {
  const _UnitCell({
    required this.unit,
    required this.isEnemy,
    required this.sideColor,
    required this.size,
    required this.active,
    required this.hit,
  });

  final BrickUnit unit;
  final bool isEnemy;
  final Color sideColor;
  final double size;
  final bool active;
  final bool hit;

  @override
  Widget build(BuildContext context) {
    final dead = !unit.isAlive;
    final lunge = active ? (isEnemy ? -10.0 : 10.0) : 0.0;
    final scale = active ? 1.1 : 1.0;
    final frameColor = dead ? Colors.white24 : sideColor;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      child: AnimatedSlide(
        offset: Offset(lunge / (size * 1.3), 0),
        duration: const Duration(milliseconds: 140),
        child: SizedBox(
          width: size * 1.28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.panelLight.withValues(alpha: dead ? 0.4 : 0.92),
                      AppColors.card.withValues(alpha: dead ? 0.4 : 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: frameColor, width: active ? 2.5 : 1.6),
                  boxShadow: [
                    if (!dead)
                      BoxShadow(
                        color: frameColor.withValues(alpha: active ? 0.6 : 0.3),
                        blurRadius: active ? 14 : 6,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    UnitSprite(
                      clazz: unit.clazz,
                      rarity: unit.rarity,
                      size: size,
                      flip: isEnemy,
                      dead: dead,
                      glow: false,
                    ),
                    if (hit && !dead)
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withValues(alpha: 0.4),
                        ),
                      ),
                    if (unit.shield > 0 && !dead)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.shield_rounded,
                            size: size * 0.28, color: AppColors.archer),
                      ),
                    // Signature-ability badge, so each class reads distinctly.
                    if (!dead)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          padding: EdgeInsets.all(size * 0.05),
                          decoration: BoxDecoration(
                            color: unit.clazz.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 1),
                          ),
                          child: Icon(unit.clazz.icon,
                              size: size * 0.24, color: Colors.white),
                        ),
                      ),
                    // Attack badge
                    if (!dead)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 9, color: AppColors.accent),
                              Text('${unit.atk}',
                                  style: AppTextStyles.body(
                                      size: 9, color: AppColors.text)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: size * 1.1,
                child: _HpBar(fraction: unit.hpFraction, dead: dead),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An oversized solo-boss figure with its name plate, ability badge and a
/// chunky HP bar — visually reads as a real boss, not just another brick.
class _BossCell extends StatelessWidget {
  const _BossCell({
    required this.unit,
    required this.isEnemy,
    required this.size,
    required this.active,
    required this.hit,
  });

  final BrickUnit unit;
  final bool isEnemy;
  final double size;
  final bool active;
  final bool hit;

  @override
  Widget build(BuildContext context) {
    final dead = !unit.isAlive;
    final s = (size * 2.4).clamp(104.0, 150.0).toDouble();
    final ability = unit.bossAbility!;
    return AnimatedScale(
      scale: active ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 160),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + ability plate.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ability.icon, size: 12, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Text(ability.label,
                      style:
                          AppTextStyles.body(size: 10, color: AppColors.text)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              if (!dead)
                Container(
                  width: s * 0.78,
                  height: s * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 2),
                    ],
                  ),
                ),
              UnitSprite(
                clazz: unit.clazz,
                size: s,
                assetOverride: unit.displayAsset,
                flip: isEnemy,
                dead: dead,
                glow: false,
              ),
              if (hit && !dead)
                Container(
                  width: s * 0.6,
                  height: s * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
              if (unit.shield > 0 && !dead)
                Positioned(
                  top: 6,
                  right: 10,
                  child: Icon(Icons.shield_rounded,
                      size: s * 0.16, color: AppColors.archer),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: s * 0.7,
            child: _HpBar(fraction: unit.hpFraction, dead: dead),
          ),
        ],
      ),
    );
  }
}

/// A stone-brick "tower" drawn behind the unit stack so the squad looks like
/// it's built into a structure rather than floating. Tinted by side color.
class BrickTowerBackdrop extends StatelessWidget {
  const BrickTowerBackdrop({super.key, required this.sideColor});
  final Color sideColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BrickTowerPainter(sideColor));
  }
}

class _BrickTowerPainter extends CustomPainter {
  _BrickTowerPainter(this.sideColor);
  final Color sideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    // Stone gradient body.
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF44506A).withValues(alpha: 0.55),
          const Color(0xFF2A3450).withValues(alpha: 0.65),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, body);

    // Brick mortar lines.
    final mortar = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const rowH = 20.0;
    final brickW = size.width / 2.4;
    var row = 0;
    for (double y = 0; y <= size.height; y += rowH) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mortar);
      final offset = row.isEven ? 0.0 : brickW / 2;
      for (double x = offset; x < size.width; x += brickW) {
        canvas.drawLine(Offset(x, y), Offset(x, y + rowH), mortar);
      }
      row++;
    }

    canvas.restore();

    // Tinted border.
    final border = Paint()
      ..color = sideColor.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect.deflate(1), border);
  }

  @override
  bool shouldRepaint(covariant _BrickTowerPainter old) =>
      old.sideColor != sideColor;
}

class _HpBar extends StatelessWidget {
  const _HpBar({required this.fraction, required this.dead});
  final double fraction;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    if (dead) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(height: 6, color: Colors.white12),
      );
    }
    final color = fraction > 0.5
        ? AppColors.success
        : (fraction > 0.25 ? AppColors.timerWarning : AppColors.danger);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 6,
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
