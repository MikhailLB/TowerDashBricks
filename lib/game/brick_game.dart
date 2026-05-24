import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'brick_constants.dart';
import 'brick_status.dart';
import 'brick_world.dart';
import 'level_config.dart';

/// Top-level Forge2D game. Owns the camera, forwards taps to the world,
/// and keeps the camera smoothly following the top of the brick tower.
class BrickGame extends Forge2DGame<BrickWorld> with TapCallbacks {
  BrickGame({
    required int Function() skinPicker,
    required LevelConfig levelConfig,
    bool craneBrakeEnabled = false,
    bool hardHatEnabled = false,
    bool speedFreezeEnabled = false,
    bool steelFoundationEnabled = false,
  }) : super(
          gravity: Vector2(0, BrickConstants.gravity),
          world: BrickWorld(
            skinPicker: skinPicker,
            levelConfig: levelConfig,
            craneBrakeEnabled: craneBrakeEnabled,
            hardHatEnabled: hardHatEnabled,
            speedFreezeEnabled: speedFreezeEnabled,
            steelFoundationEnabled: steelFoundationEnabled,
          ),
        );

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyZoom(size);
  }

  void _applyZoom(Vector2 size) {
    if (size.x <= 0) return;
    camera.viewfinder.zoom = size.x / BrickConstants.worldWidth;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyZoom(canvasSize);
    camera.viewfinder.position = BrickConstants.initialCameraTarget;
    world.startRound();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (world.status.value == BrickStatus.paused ||
        world.status.value == BrickStatus.gameOver ||
        world.status.value == BrickStatus.timedOut ||
        world.status.value == BrickStatus.levelComplete) {
      return;
    }
    world.dropBrick();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!world.isMounted) return;
    _followTower(dt);
  }

  void _followTower(double dt) {
    final desiredCenterY =
        world.currentTopY - BrickConstants.cameraOffsetBelowCenter;
    final current = camera.viewfinder.position.y;
    final target = math.min(current, desiredCenterY);
    final newY = current +
        (target - current) *
            (1 - math.exp(-dt * BrickConstants.cameraLerp));
    camera.viewfinder.position = Vector2(0, newY);
  }

  void setPaused(bool value) {
    world.setPaused(value);
    paused = value;
  }

  void requestBlueprintRetry() {
    world.applyBlueprintRetry();
  }
}
