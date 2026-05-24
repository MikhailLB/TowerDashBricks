import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../app/tdb_assets.dart';
import '../../services/audio_service.dart';
import '../brick_constants.dart';

/// A single dynamic physics brick dropped from the crane.
class FallingBrick extends BodyComponent with ContactCallbacks {
  FallingBrick({
    required this.skinIndex,
    required this.spawnPosition,
    required this.spawnVelocity,
    required this.spawnAngularVelocity,
  }) : super(priority: 5);

  /// 1..6 — matches tdb_brick_0X.webp skin files.
  final int skinIndex;
  final Vector2 spawnPosition;
  final Vector2 spawnVelocity;
  final double spawnAngularVelocity;

  late final ui.Image _image;

  /// True once the brick is at rest and counted into the tower.
  bool placed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(TdbAssets.brick(skinIndex));
  }

  @override
  Body createBody() {
    final hw = BrickConstants.blockWidth / 2;
    final hh = BrickConstants.blockHeight / 2;
    final shape = PolygonShape()..setAsBoxXY(hw, hh);
    final body = world.createBody(BodyDef(
      type: BodyType.dynamic,
      position: spawnPosition.clone(),
      linearVelocity: spawnVelocity.clone(),
      angularVelocity: spawnAngularVelocity,
      bullet: true,
      userData: 'falling_brick',
    ));
    body.createFixture(FixtureDef(
      shape,
      density: 1.4,
      friction: 0.92,
      restitution: 0.02,
    ));
    return body;
  }

  bool _impactCooldown = false;

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    if (_impactCooldown) return;
    final maxImpulse = impulse.normalImpulses.isEmpty
        ? 0.0
        : impulse.normalImpulses.reduce((a, b) => a > b ? a : b);
    if (maxImpulse < 0.6) return;
    _impactCooldown = true;
    AudioService.instance.playSfx(Sfx.blockLand);
    AudioService.instance.vibrate();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      _impactCooldown = false;
    });
  }

  @override
  void render(Canvas canvas) {
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: BrickConstants.blockWidth,
      height: BrickConstants.blockHeight,
    );
    final src = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    canvas.drawImageRect(
      _image,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  /// World-space top Y of the brick (smallest Y across all four corners).
  double get topY {
    final t = body.transform;
    final hw = BrickConstants.blockWidth / 2;
    final hh = BrickConstants.blockHeight / 2;
    final corners = <Vector2>[
      Vector2(-hw, -hh),
      Vector2(hw, -hh),
      Vector2(hw, hh),
      Vector2(-hw, hh),
    ];
    var minY = double.infinity;
    for (final c in corners) {
      final w = t.p + Vector2(
        c.x * t.q.cos - c.y * t.q.sin,
        c.x * t.q.sin + c.y * t.q.cos,
      );
      if (w.y < minY) minY = w.y;
    }
    return minY;
  }
}
