import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// Manages a set of slowly drifting clouds in the background.
class CloudLayer extends Component {
  CloudLayer() : super(priority: -3);

  static const _count = 4;
  final _rng = math.Random();
  final _clouds = <_Cloud>[];
  late ui.Image _image;
  bool _ready = false;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(TdbAssets.cloud);
    _ready = true;
    for (var i = 0; i < _count; i++) {
      _clouds.add(_randomCloud());
    }
  }

  _Cloud _randomCloud() {
    return _Cloud(
      x: (_rng.nextDouble() - 0.5) * BrickConstants.worldWidth * 1.4,
      y: -BrickConstants.worldHeight * (_rng.nextDouble() * 2 + 0.5),
      width: 2.5 + _rng.nextDouble() * 1.5,
      speed: 0.1 + _rng.nextDouble() * 0.15,
      opacity: 0.25 + _rng.nextDouble() * 0.35,
    );
  }

  @override
  void update(double dt) {
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > BrickConstants.worldWidth) {
        c.x = -BrickConstants.worldWidth;
        c.y = -BrickConstants.worldHeight * (_rng.nextDouble() * 2 + 0.5);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    for (final c in _clouds) {
      final paint = Paint()
        ..filterQuality = FilterQuality.low
        ..color = Colors.white.withValues(alpha: c.opacity);
      canvas.drawImageRect(
        _image,
        Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
        Rect.fromCenter(
          center: Offset(c.x, c.y),
          width: c.width,
          height: c.width * _image.height / _image.width,
        ),
        paint,
      );
    }
  }
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
    required this.opacity,
  });

  double x;
  double y;
  final double width;
  final double speed;
  final double opacity;
}
