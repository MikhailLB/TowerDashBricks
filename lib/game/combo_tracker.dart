import 'brick_constants.dart';

/// Tracks consecutive successful brick placements and returns the current
/// score multiplier.
///
/// Tier 1 (0–2 streak):   1×
/// Tier 2 (3–5 streak):   2×
/// Tier 3 (6+ streak):    3×
class ComboTracker {
  int _streak = 0;

  int get streak => _streak;

  /// Current multiplier based on streak count.
  int get multiplier {
    if (_streak >= BrickConstants.comboTier3) return 3;
    if (_streak >= BrickConstants.comboTier2) return 2;
    return 1;
  }

  /// Call on a successful placement. Returns the new multiplier.
  int onSuccess() {
    _streak++;
    return multiplier;
  }

  /// Call on a failed placement. Resets the streak.
  void onFail() {
    _streak = 0;
  }

  void reset() {
    _streak = 0;
  }
}
