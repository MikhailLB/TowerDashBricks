import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/unit_class.dart';

/// A damage / heal number that floats upward and fades, then removes itself.
class FloatingNumber extends StatefulWidget {
  const FloatingNumber({
    super.key,
    required this.center,
    required this.text,
    required this.color,
    required this.onDone,
    this.big = false,
  });

  final Offset center;
  final String text;
  final Color color;
  final VoidCallback onDone;
  final bool big;

  @override
  State<FloatingNumber> createState() => _FloatingNumberState();
}

class _FloatingNumberState extends State<FloatingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final dy = -34 * Curves.easeOut.transform(t);
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
        final scale = 0.7 + 0.5 * Curves.elasticOut.transform(t.clamp(0, 1));
        return Positioned(
          left: widget.center.dx - 40,
          top: widget.center.dy - 14 + dy,
          width: 80,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: AppTextStyles.score(
                  size: widget.big ? 26 : 20,
                  color: widget.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small projectile that flies from [start] to [end] and removes itself.
class Projectile extends StatefulWidget {
  const Projectile({
    super.key,
    required this.start,
    required this.end,
    required this.attackerClass,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final UnitClass attackerClass;
  final VoidCallback onDone;

  @override
  State<Projectile> createState() => _ProjectileState();
}

class _ProjectileState extends State<Projectile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.attackerClass.color;
    final isMagic = widget.attackerClass == UnitClass.mage;
    final isBomb = widget.attackerClass == UnitClass.bomber;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeIn.transform(_c.value);
        final pos = Offset.lerp(widget.start, widget.end, t)!;
        final arc = -34 * (t * (1 - t)) * 4; // simple lob
        final size = isBomb ? 16.0 : (isMagic ? 14.0 : 10.0);
        return Positioned(
          left: pos.dx - size / 2,
          top: pos.dy - size / 2 + (isBomb ? arc : 0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isMagic ? color : (isBomb ? AppColors.accent : color),
              shape: isBomb ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isBomb ? null : BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A burst of small bricks flying outward (used when a unit is destroyed).
class ShatterBurst extends StatefulWidget {
  const ShatterBurst({
    super.key,
    required this.center,
    required this.color,
    required this.onDone,
  });

  final Offset center;
  final Color color;
  final VoidCallback onDone;

  @override
  State<ShatterBurst> createState() => _ShatterBurstState();
}

class _ShatterBurstState extends State<ShatterBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final List<_Shard> _shards;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _shards = List.generate(7, (_) {
      final ang = rng.nextDouble() * 2 * math.pi;
      final speed = 40 + rng.nextDouble() * 60;
      return _Shard(
        vx: math.cos(ang) * speed,
        vy: math.sin(ang) * speed - 40,
        size: 5 + rng.nextDouble() * 7,
        rot: rng.nextDouble() * 6,
      );
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return Stack(
          children: [
            for (final s in _shards)
              Positioned(
                left: widget.center.dx + s.vx * t,
                top: widget.center.dy + s.vy * t + 90 * t * t,
                child: Transform.rotate(
                  angle: s.rot * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Container(
                      width: s.size,
                      height: s.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      ),
    );
  }
}

class _Shard {
  _Shard({
    required this.vx,
    required this.vy,
    required this.size,
    required this.rot,
  });
  final double vx;
  final double vy;
  final double size;
  final double rot;
}

/// Brief expanding impact ring at [center].
class ImpactRing extends StatefulWidget {
  const ImpactRing({
    super.key,
    required this.center,
    required this.color,
    required this.onDone,
  });

  final Offset center;
  final Color color;
  final VoidCallback onDone;

  @override
  State<ImpactRing> createState() => _ImpactRingState();
}

class _ImpactRingState extends State<ImpactRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final r = 6 + 26 * Curves.easeOut.transform(t);
        return Positioned(
          left: widget.center.dx - r,
          top: widget.center.dy - r,
          width: r * 2,
          height: r * 2,
          child: Opacity(
            opacity: (1 - t).clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}
