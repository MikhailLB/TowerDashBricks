import 'package:flame/components.dart';

/// All gameplay constants for TowerDash Bricks portrait 9:16 world.
///
/// Coordinates are in Forge2D meters. Y grows downward (Box2D convention),
/// so stacking "up" means decreasing Y.
class BrickConstants {
  /// Logical render size in meters. Camera zoom is set so [worldWidth] fits
  /// exactly horizontally — gives the correct 9:16 fill on any portrait phone.
  static const worldWidth = 9.0;
  static const worldHeight = 16.0;

  /// Camera position at game start (world space).
  static Vector2 get initialCameraTarget => Vector2(0, 1.0);

  /// Y of the ground collision floor. Below this = failed placement.
  static const groundTopY = 7.5;

  /// Visual height of the ground decal image in meters (keeps it from stretching).
  static const groundDecalHeight = 1.5;

  /// Base platform the player stacks on (the Dash Bricks base building).
  /// Bottom sits exactly at groundTopY: 7.5 - 2.7 = 4.8
  static const startBuildingTopY = 4.8;
  static const startBuildingWidth = 3.0;
  static const startBuildingHeight = 2.7;

  /// Block physics dimensions in meters.
  static const blockWidth = 3.6;
  static const blockHeight = 3.0;

  // --- Crane (hook) --------------------------------------------------------

  /// Peak horizontal amplitude of the crane slide (meters from world centre).
  static const craneAmplitude = 2.5;

  /// Gap between the hanging block's bottom edge and the tower top.
  static const craneBlockOffsetAboveTop = 1.0;

  /// Crane sprite rendered height in meters.
  static const craneSpriteHeight = 5.0;

  /// Crane centre sits this many meters ABOVE the camera centre.
  static const craneScreenAnchor = 7.5;

  /// Starting half-period (seconds per one-way traverse). Higher = slower.
  static const craneInitialHalfPeriod = 1.7;

  /// Fastest the crane can ever get.
  static const craneMinHalfPeriod = 0.55;

  /// Speed increase applied per successfully placed block.
  static const craneSpeedUpPerBlock = 0.05;

  // --- Physics -------------------------------------------------------------

  static const gravity = 26.0;
  static const settleSpeedThreshold = 0.25;
  static const settleHoldSeconds = 0.45;
  static const settleTimeoutSeconds = 4.0;

  /// Minimum horizontal overlap (meters) required to count a brick as placed.
  static const minOverlapToCount = 1.2;

  // --- Camera --------------------------------------------------------------

  static const cameraOffsetBelowCenter = 2.5;
  static const cameraLerp = 4.0;

  // --- Scoring -------------------------------------------------------------

  static const baseRewardPerBrick = 1;

  // --- Combo ---------------------------------------------------------------

  /// Consecutive placements needed for multiplier tiers.
  static const comboTier2 = 3;
  static const comboTier3 = 6;
}
