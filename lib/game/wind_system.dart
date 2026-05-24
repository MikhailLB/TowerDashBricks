import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';

/// Applies periodic wind gusts to a falling brick body.
///
/// Wind is enabled only on levels 6+ (controlled by [windStrength]).
/// Each gust fires for [_gustDuration] seconds, then there is a calm
/// period of [_calmDuration] seconds before the next gust.
class WindSystem {
  WindSystem({required this.windStrength});

  /// Lateral impulse magnitude per second (Forge2D units).
  /// 0 = no wind, 0.5 = light, 1.5 = medium, 3.0 = strong.
  final double windStrength;

  static const _gustDuration = 0.6;
  static const _calmDuration = 1.8;

  final _rng = math.Random();
  double _timer = 0;
  bool _gusting = false;
  double _direction = 1;

  bool get active => windStrength > 0;

  /// Call every frame while a brick is falling.
  /// [dt] — seconds since last frame.
  /// [body] — the active falling brick body.
  void update(double dt, Body? body) {
    if (!active || body == null) return;

    _timer -= dt;
    if (_timer <= 0) {
      if (_gusting) {
        _gusting = false;
        _timer = _calmDuration + _rng.nextDouble() * 0.8;
      } else {
        _gusting = true;
        _direction = _rng.nextBool() ? 1.0 : -1.0;
        _timer = _gustDuration;
      }
    }

    if (_gusting) {
      body.applyForce(Vector2(_direction * windStrength * 2.0, 0));
    }
  }

  void reset() {
    _timer = _calmDuration;
    _gusting = false;
  }
}
