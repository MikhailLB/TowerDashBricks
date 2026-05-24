import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// Full-screen sky background image that fills the world viewport.
class SkyBackground extends PositionComponent {
  SkyBackground() : super(priority: -10);

  late ui.Image _image;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(TdbAssets.sky);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: BrickConstants.worldWidth,
        height: BrickConstants.worldHeight * 4,
      ),
      Paint()..filterQuality = FilterQuality.low,
    );
  }
}
