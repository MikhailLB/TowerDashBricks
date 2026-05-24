import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// City background layer shown behind the starting platform.
class StartBg extends PositionComponent {
  StartBg() : super(priority: -5);

  late ui.Image _image;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(TdbAssets.cityBg);
  }

  @override
  void render(Canvas canvas) {
    final bgH = BrickConstants.startBuildingHeight + 3.0;
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      Rect.fromLTWH(
        -BrickConstants.worldWidth / 2,
        BrickConstants.groundTopY - bgH,
        BrickConstants.worldWidth,
        bgH,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
