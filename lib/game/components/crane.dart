import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/tdb_assets.dart';
import '../brick_constants.dart';

/// The construction crane + the brick currently teased above the tower.
///
/// The crane slides horizontally across the top of the viewport. Its Y
/// position is pinned to the camera centre (via [cameraCenterY]) so it
/// always stays near the top of the screen even as the camera follows the
/// growing tower. The hanging brick is anchored to [topY] (top of the
/// current tower), keeping the chain length visually constant.
class Crane extends PositionComponent {
  Crane({required this.skinIndexProvider}) : super(priority: 10);

  final int Function() skinIndexProvider;

  late ui.Image _craneImage;
  final Map<int, ui.Image> _brickImages = {};
  late ui.Image _brickImage;
  int _currentSkin = 1;

  /// Top-of-tower Y in world space. Updated every frame by BrickWorld.
  double topY = BrickConstants.startBuildingTopY;

  /// Camera centre Y in world space. Updated every frame by BrickWorld.
  double cameraCenterY = 0;

  /// Crane slide speed (half-period in seconds for one-way traverse).
  double halfPeriod = BrickConstants.craneInitialHalfPeriod;

  double _phase = 0;
  bool _hasBlock = true;

  double get currentX => math.sin(_phase) * BrickConstants.craneAmplitude;

  double get currentY =>
      topY -
      BrickConstants.craneBlockOffsetAboveTop -
      BrickConstants.blockHeight / 2;

  double get currentVelocityX =>
      math.cos(_phase) *
      BrickConstants.craneAmplitude *
      (math.pi / halfPeriod);

  double get blockY => currentY - BrickConstants.blockHeight / 2;

  bool get hasBlock => _hasBlock;

  @override
  Future<void> onLoad() async {
    _craneImage = await Flame.images.load(TdbAssets.crane);
    for (var i = 1; i <= 6; i++) {
      _brickImages[i] = await Flame.images.load(TdbAssets.brick(i));
    }
    _currentSkin = skinIndexProvider();
    _brickImage = _brickImages[_currentSkin]!;
  }

  void releaseBlock() {
    _hasBlock = false;
  }

  void attachNewBlock() {
    _currentSkin = skinIndexProvider();
    _brickImage = _brickImages[_currentSkin] ?? _brickImage;
    _hasBlock = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * (math.pi / halfPeriod);
    if (_phase > math.pi * 2) _phase -= math.pi * 2;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    final cx = currentX;
    final blockCy = currentY;
    final blockTopY = blockCy - BrickConstants.blockHeight / 2;

    const craneSpriteHeight = BrickConstants.craneSpriteHeight;
    final craneAspect = _craneImage.width / _craneImage.height;
    final craneSpriteWidth = craneSpriteHeight * craneAspect;
    final craneCenterY = cameraCenterY - BrickConstants.craneScreenAnchor;
    final craneBottomY = craneCenterY + craneSpriteHeight / 2;

    canvas.drawImageRect(
      _craneImage,
      Rect.fromLTWH(
        0,
        0,
        _craneImage.width.toDouble(),
        _craneImage.height.toDouble(),
      ),
      Rect.fromCenter(
        center: Offset(cx, craneCenterY),
        width: craneSpriteWidth,
        height: craneSpriteHeight,
      ),
      paint,
    );

    if (_hasBlock) {
      final inset = BrickConstants.blockWidth * 0.08;
      final attachLeftX = cx - BrickConstants.blockWidth / 2 + inset;
      final attachRightX = cx + BrickConstants.blockWidth / 2 - inset;
      final chainPaint = Paint()
        ..color = const Color(0xFFF5A623)
        ..strokeWidth = 0.10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx, craneBottomY),
        Offset(attachLeftX, blockTopY),
        chainPaint,
      );
      canvas.drawLine(
        Offset(cx, craneBottomY),
        Offset(attachRightX, blockTopY),
        chainPaint,
      );

      canvas.drawImageRect(
        _brickImage,
        Rect.fromLTWH(
          0,
          0,
          _brickImage.width.toDouble(),
          _brickImage.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset(cx, blockCy),
          width: BrickConstants.blockWidth,
          height: BrickConstants.blockHeight,
        ),
        paint,
      );
    }
  }
}
