import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// The base building from which the player starts stacking bricks.
/// Has a static physics body for collision and a decorative sprite.
class StartBuilding extends BodyComponent {
  StartBuilding() : super(priority: 4);

  late ui.Image _image;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(TdbAssets.base);
  }

  @override
  Body createBody() {
    final hw = BrickConstants.startBuildingWidth / 2;
    final hh = BrickConstants.startBuildingHeight / 2;
    final shape = PolygonShape()..setAsBoxXY(hw, hh);
    final centerY = BrickConstants.startBuildingTopY +
        BrickConstants.startBuildingHeight / 2;
    final body = world.createBody(
      BodyDef(
        type: BodyType.static,
        position: Vector2(0, centerY),
      ),
    );
    body.createFixture(FixtureDef(shape, friction: 0.8));
    return body;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(
      _image,
      Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      Rect.fromCenter(
        center: Offset.zero,
        width: BrickConstants.startBuildingWidth,
        height: BrickConstants.startBuildingHeight,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }
}
