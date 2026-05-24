import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../services/audio_service.dart';
import 'brick_constants.dart';
import 'brick_game.dart';
import 'brick_status.dart';
import 'combo_tracker.dart';
import 'components/cloud.dart';
import 'components/crane.dart';
import 'components/falling_brick.dart';
import 'components/ground.dart';
import 'components/sky_background.dart';
import 'components/start_bg.dart';
import 'components/start_building.dart';
import 'level_config.dart';
import 'wind_system.dart';

/// Hosts every world-space component (background, bricks, crane, ground) and
/// drives the Brick Tower Rush gameplay state machine with countdown timer
/// and combo multiplier.
class BrickWorld extends Forge2DWorld with HasGameReference<BrickGame> {
  BrickWorld({
    required this.skinPicker,
    required this.levelConfig,
    this.craneBrakeEnabled = false,
    this.hardHatEnabled = false,
    this.speedFreezeEnabled = false,
    this.steelFoundationEnabled = false,
  }) : crane = Crane(skinIndexProvider: skinPicker);

  final int Function() skinPicker;
  final LevelConfig levelConfig;
  final bool craneBrakeEnabled;
  final bool hardHatEnabled;
  final bool speedFreezeEnabled;
  final bool steelFoundationEnabled;

  final Crane crane;
  final List<FallingBrick> _placedBricks = [];
  FallingBrick? _activeBrick;

  double currentTopY = BrickConstants.startBuildingTopY;
  double _settleTimer = 0;
  double _fallTimer = 0;

  /// Countdown timer — seconds remaining.
  double _timeRemaining = 0;

  final ComboTracker _combo = ComboTracker();
  late WindSystem _wind;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> bricksPlaced = ValueNotifier(0);
  final ValueNotifier<BrickStatus> status = ValueNotifier(BrickStatus.ready);
  final ValueNotifier<double> timeRemaining = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(1);

  bool _secondChanceUsedThisRun = false;
  bool _hardHatUsedThisRun = false;

  double _craneBrakeSecondsRemaining = 0;
  static const _craneBrakeFactor = 1.8;

  int _speedFreezeBlocksRemaining = 0;
  int _steelFoundationBlocksRemaining = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(SkyBackground());
    await add(StartBg());
    await add(GroundDecal());
    await add(Ground());
    await add(StartBuilding());
    await add(crane);
    await add(CloudLayer());
  }

  void startRound() {
    _placedBricks.clear();
    _activeBrick = null;
    _settleTimer = 0;
    _fallTimer = 0;
    score.value = 0;
    bricksPlaced.value = 0;
    _combo.reset();
    combo.value = 1;
    currentTopY = BrickConstants.startBuildingTopY;
    crane.topY = currentTopY;
    crane.halfPeriod = BrickConstants.craneInitialHalfPeriod /
        levelConfig.craneSpeedMultiplier;

    _timeRemaining = levelConfig.timeLimit.toDouble();
    timeRemaining.value = _timeRemaining;

    _wind = WindSystem(windStrength: levelConfig.windStrength);

    _secondChanceUsedThisRun = false;
    _hardHatUsedThisRun = false;

    if (craneBrakeEnabled) {
      _craneBrakeSecondsRemaining = 6.0;
    }
    if (speedFreezeEnabled) {
      _speedFreezeBlocksRemaining = 10;
    }
    if (steelFoundationEnabled) {
      _steelFoundationBlocksRemaining = 3;
    }
    status.value = BrickStatus.swinging;
  }

  void dropBrick() {
    if (status.value != BrickStatus.swinging || !crane.hasBlock) return;
    final spawnPos = Vector2(crane.currentX, crane.currentY);
    final velocity = Vector2(crane.currentVelocityX, 0);
    final brick = FallingBrick(
      skinIndex: skinPicker(),
      spawnPosition: spawnPos,
      spawnVelocity: velocity,
      spawnAngularVelocity: 0,
    );
    _activeBrick = brick;
    add(brick);
    crane.releaseBlock();
    _settleTimer = 0;
    _fallTimer = 0;
    _wind.reset();
    status.value = BrickStatus.falling;
  }

  void applyBlueprintRetry() {
    if (status.value != BrickStatus.gameOver &&
        status.value != BrickStatus.timedOut) {
      return;
    }
    if (_secondChanceUsedThisRun) return;
    _secondChanceUsedThisRun = true;
    _removeActiveBrick();
    crane.attachNewBlock();
    // Restore some time on second chance
    _timeRemaining = math.max(_timeRemaining, 15.0);
    timeRemaining.value = _timeRemaining;
    status.value = BrickStatus.swinging;
    _settleTimer = 0;
    _fallTimer = 0;
  }

  void setPaused(bool value) {
    if (value) {
      if (status.value == BrickStatus.swinging ||
          status.value == BrickStatus.falling) {
        status.value = BrickStatus.paused;
      }
    } else {
      if (status.value == BrickStatus.paused) {
        status.value = _activeBrick != null
            ? BrickStatus.falling
            : BrickStatus.swinging;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (status.value == BrickStatus.ready ||
        status.value == BrickStatus.paused ||
        status.value == BrickStatus.gameOver ||
        status.value == BrickStatus.timedOut ||
        status.value == BrickStatus.levelComplete) {
      return;
    }

    // Tick countdown timer
    _timeRemaining -= dt;
    timeRemaining.value = math.max(0, _timeRemaining);
    if (_timeRemaining <= 0) {
      _handleTimeout();
      return;
    }

    _updateCraneSpeed(dt);

    var top = BrickConstants.startBuildingTopY;
    for (final b in _placedBricks) {
      final t = b.topY;
      if (t < top) top = t;
    }
    if (_activeBrick != null && _activeBrick!.placed) {
      final t = _activeBrick!.topY;
      if (t < top) top = t;
    }
    currentTopY = top;
    crane.topY = currentTopY;
    crane.cameraCenterY = game.camera.viewfinder.position.y;

    if (status.value == BrickStatus.falling && _activeBrick != null) {
      _wind.update(dt, _activeBrick?.body);
      _evaluateFalling(dt);
    }
  }

  void _handleTimeout() {
    AudioService.instance.playSfx(Sfx.blockFall);
    status.value = BrickStatus.timedOut;
  }

  void _updateCraneSpeed(double dt) {
    final placed = _placedBricks.length;
    double base;
    if (_speedFreezeBlocksRemaining > 0) {
      base = BrickConstants.craneInitialHalfPeriod /
          levelConfig.craneSpeedMultiplier;
    } else {
      final raw = (BrickConstants.craneInitialHalfPeriod /
              levelConfig.craneSpeedMultiplier) -
          placed * BrickConstants.craneSpeedUpPerBlock;
      base = math.max(
        BrickConstants.craneMinHalfPeriod / levelConfig.craneSpeedMultiplier,
        raw,
      );
    }

    if (_craneBrakeSecondsRemaining > 0) {
      _craneBrakeSecondsRemaining =
          math.max(0, _craneBrakeSecondsRemaining - dt);
      crane.halfPeriod = base * _craneBrakeFactor;
    } else {
      crane.halfPeriod = base;
    }
  }

  void _evaluateFalling(double dt) {
    final brick = _activeBrick!;
    if (!brick.isMounted) return;
    final body = brick.body;
    final v = body.linearVelocity;
    final speed = v.length;

    _fallTimer += dt;
    if (speed < BrickConstants.settleSpeedThreshold) {
      _settleTimer += dt;
    } else {
      _settleTimer = 0;
    }

    final settled = _settleTimer >= BrickConstants.settleHoldSeconds;
    final timedOut = _fallTimer >= BrickConstants.settleTimeoutSeconds;
    final fellThrough = body.position.y > BrickConstants.groundTopY - 0.4;

    if (fellThrough) {
      _handleFail();
      return;
    }
    if (settled || timedOut) {
      _handleLanding();
    }
  }

  void _handleLanding() {
    final brick = _activeBrick!;
    final brickTop = brick.topY;
    final brickX = brick.body.position.x;

    final supportTop = _findSupportTopAt(brickX, exclude: brick);
    final supportingBrick = _findTopBrick(exclude: brick);

    final landedAboveSomething = brickTop < supportTop + 0.05;
    final overlap = supportingBrick == null
        ? BrickConstants.blockWidth
        : _horizontalOverlap(brick, supportingBrick);
    final tilt = brick.body.angle.abs();

    final effectiveMinOverlap = _steelFoundationBlocksRemaining > 0
        ? BrickConstants.minOverlapToCount *
            levelConfig.overlapMultiplier /
            2.0
        : BrickConstants.minOverlapToCount * levelConfig.overlapMultiplier;

    final tooMuchTilt = tilt > 0.7;
    final tooLittleOverlap = overlap < effectiveMinOverlap;

    if (!landedAboveSomething || tooMuchTilt || tooLittleOverlap) {
      _handleFail();
      return;
    }

    brick.placed = true;
    _placedBricks.add(brick);

    final multiplier = _combo.onSuccess();
    combo.value = multiplier;
    bricksPlaced.value = _placedBricks.length;
    score.value = _placedBricks.length *
        BrickConstants.baseRewardPerBrick *
        multiplier;

    _activeBrick = null;
    _settleTimer = 0;
    _fallTimer = 0;

    if (_speedFreezeBlocksRemaining > 0) _speedFreezeBlocksRemaining--;
    if (_steelFoundationBlocksRemaining > 0) _steelFoundationBlocksRemaining--;

    if (_placedBricks.length >= levelConfig.targetBlocks) {
      status.value = BrickStatus.levelComplete;
      return;
    }

    crane.attachNewBlock();
    status.value = BrickStatus.swinging;
  }

  void _handleFail() {
    // Hard Hat: silently forgive one bad placement.
    if (hardHatEnabled && !_hardHatUsedThisRun) {
      _hardHatUsedThisRun = true;
      _removeActiveBrick();
      crane.attachNewBlock();
      status.value = BrickStatus.swinging;
      _settleTimer = 0;
      _fallTimer = 0;
      _combo.onFail();
      combo.value = 1;
      return;
    }
    _combo.onFail();
    combo.value = 1;
    AudioService.instance.playSfx(Sfx.blockFall);
    AudioService.instance.vibrate(heavy: true);
    status.value = BrickStatus.gameOver;
  }

  void _removeActiveBrick() {
    final brick = _activeBrick;
    _activeBrick = null;
    if (brick != null && brick.isMounted) {
      brick.removeFromParent();
    }
  }

  FallingBrick? _findTopBrick({FallingBrick? exclude}) {
    FallingBrick? top;
    var minY = double.infinity;
    for (final b in _placedBricks) {
      if (identical(b, exclude)) continue;
      final y = b.topY;
      if (y < minY) {
        minY = y;
        top = b;
      }
    }
    return top;
  }

  double _findSupportTopAt(double x, {FallingBrick? exclude}) {
    final hw = BrickConstants.startBuildingWidth / 2;
    var best = double.infinity;
    if (x.abs() <= hw) {
      best = BrickConstants.startBuildingTopY;
    }
    for (final b in _placedBricks) {
      if (identical(b, exclude)) continue;
      final dx = (b.body.position.x - x).abs();
      if (dx < BrickConstants.blockWidth / 2 + 0.1) {
        final y = b.topY;
        if (y < best) best = y;
      }
    }
    return best;
  }

  double _horizontalOverlap(FallingBrick a, FallingBrick b) {
    final aLeft = a.body.position.x - BrickConstants.blockWidth / 2;
    final aRight = a.body.position.x + BrickConstants.blockWidth / 2;
    final bLeft = b.body.position.x - BrickConstants.blockWidth / 2;
    final bRight = b.body.position.x + BrickConstants.blockWidth / 2;
    final overlap =
        math.min(aRight, bRight) - math.max(aLeft, bLeft);
    return overlap.clamp(0, BrickConstants.blockWidth).toDouble();
  }
}
