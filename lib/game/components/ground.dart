import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// Static ground physics body + decorative ground sprite.
class Ground extends BodyComponent {
  Ground() : super(priority: 2);

  @override
  Body createBody() {
    final shape = EdgeShape()
      ..set(
        Vector2(-BrickConstants.worldWidth / 2, BrickConstants.groundTopY),
        Vector2(BrickConstants.worldWidth / 2, BrickConstants.groundTopY),
      );
    final body = world.createBody(BodyDef(type: BodyType.static));
    body.createFixture(FixtureDef(shape, friction: 0.6));
    return body;
  }
}

/// Decorative ground image drawn above the physics ground.
class GroundDecal extends PositionComponent {
  GroundDecal() : super(priority: 3);

  late ui.Image _image;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(TdbAssets.ground);
  }

  @override
  void render(Canvas canvas) {
    const left = -BrickConstants.worldWidth / 2;
    const width = BrickConstants.worldWidth;
    // Fill everything below groundTopY with a solid earth colour first.
    canvas.drawRect(
      Rect.fromLTWH(left, BrickConstants.groundTopY, width,
          BrickConstants.worldHeight * 4),
      Paint()..color = const Color(0xFF2A1A0A),
    );
    // Then draw the ground-texture strip on top.
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      Rect.fromLTWH(
        left,
        BrickConstants.groundTopY,
        width,
        BrickConstants.groundDecalHeight,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
