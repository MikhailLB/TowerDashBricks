import 'package:flutter/material.dart';

import '../game/unit_class.dart';

/// Renders a unit's class sprite with a colored suit glow. Used inside towers,
/// cards and the collection grid.
class UnitSprite extends StatelessWidget {
  const UnitSprite({
    super.key,
    required this.clazz,
    this.size = 72,
    this.rarity,
    this.flip = false,
    this.dead = false,
    this.glow = true,
    this.assetOverride,
  });

  final UnitClass clazz;
  final double size;
  final Rarity? rarity;
  final bool flip;
  final bool dead;
  final bool glow;

  /// Optional sprite path that replaces the class sprite (used by bosses).
  final String? assetOverride;

  @override
  Widget build(BuildContext context) {
    final tint = (rarity?.color ?? clazz.color);
    Widget image = Image.asset(
      assetOverride ?? clazz.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    if (dead) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(opacity: 0.45, child: image),
      );
    }

    if (flip) {
      image = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(3.1415926),
        child: image,
      );
    }

    if (!glow || dead) return SizedBox(width: size, height: size, child: image);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.35),
              blurRadius: size * 0.22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: image,
      ),
    );
  }
}
