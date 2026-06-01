import 'package:flutter/foundation.dart';

import 'puzzle_level.dart';

/// State of a single grid cell as edited by the player.
enum CellMark {
  /// Untouched.
  empty,

  /// A brick has been laid here.
  brick,

  /// Player marked this as a known gap (the X / cross).
  cross,
}

/// Two editing modes the player toggles between.
enum EditMode { lay, mark }

/// Overall round status, drives the Flutter overlays.
enum BlueprintStatus { building, paused, complete, scrapped }

/// Pure-Dart logic for a Blueprint (nonogram) round. No game engine — the UI
/// listens to this [ChangeNotifier] and repaints.
class NonogramController extends ChangeNotifier {
  NonogramController(this.level)
      : _grid = List.generate(
          level.rowCount,
          (_) => List.filled(level.colCount, CellMark.empty),
        );

  final PuzzleLevel level;

  final List<List<CellMark>> _grid;
  EditMode _mode = EditMode.lay;
  int _mistakes = 0;
  int _bricksLaid = 0;
  int _hintsUsed = 0;
  BlueprintStatus _status = BlueprintStatus.building;

  /// The last cell that triggered a wrong placement (for a brief flash), or null.
  int? flashRow;
  int? flashCol;

  int get rows => level.rowCount;
  int get cols => level.colCount;
  EditMode get mode => _mode;
  int get mistakes => _mistakes;
  int get livesLeft => (level.lives - _mistakes).clamp(0, level.lives);
  int get maxLives => level.lives;
  int get bricksLaid => _bricksLaid;
  int get bricksTotal => level.brickCount;
  int get hintsUsed => _hintsUsed;
  BlueprintStatus get status => _status;
  bool get isInteractive => _status == BlueprintStatus.building;

  CellMark cellAt(int r, int c) => _grid[r][c];

  void toggleMode() {
    _mode = _mode == EditMode.lay ? EditMode.mark : EditMode.lay;
    notifyListeners();
  }

  void setMode(EditMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void pause() {
    if (_status != BlueprintStatus.building) return;
    _status = BlueprintStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != BlueprintStatus.paused) return;
    _status = BlueprintStatus.building;
    notifyListeners();
  }

  /// Result of a single tap, lets the UI play the matching sound/haptic.
  TapResult handleTap(int r, int c) {
    if (!isInteractive) return TapResult.ignored;
    flashRow = null;
    flashCol = null;

    final cell = _grid[r][c];
    final shouldBeBrick = level.solutionAt(r, c);

    if (_mode == EditMode.lay) {
      // Tapping an already-laid brick removes it (free correction).
      if (cell == CellMark.brick) {
        _grid[r][c] = CellMark.empty;
        _bricksLaid--;
        notifyListeners();
        return TapResult.removed;
      }
      if (cell == CellMark.cross) {
        // Don't lay on a crossed cell — clear the cross first.
        return TapResult.ignored;
      }
      if (shouldBeBrick) {
        _grid[r][c] = CellMark.brick;
        _bricksLaid++;
        final won = _checkComplete();
        notifyListeners();
        return won ? TapResult.completedRound : TapResult.placed;
      } else {
        // Wrong placement — costs a life and auto-marks the gap.
        _mistakes++;
        _grid[r][c] = CellMark.cross;
        flashRow = r;
        flashCol = c;
        if (_mistakes >= level.lives) {
          _status = BlueprintStatus.scrapped;
          notifyListeners();
          return TapResult.scrappedRound;
        }
        notifyListeners();
        return TapResult.mistake;
      }
    } else {
      // Mark mode — toggle a cross on empty cells, never costs a life.
      if (cell == CellMark.brick) return TapResult.ignored;
      _grid[r][c] = cell == CellMark.cross ? CellMark.empty : CellMark.cross;
      notifyListeners();
      return TapResult.marked;
    }
  }

  /// Drag painting: only adds bricks/crosses to empty cells (never removes),
  /// so sweeping a finger across the grid feels predictable.
  TapResult dragPaint(int r, int c) {
    if (!isInteractive) return TapResult.ignored;
    final cell = _grid[r][c];
    if (cell != CellMark.empty) return TapResult.ignored;

    if (_mode == EditMode.lay) {
      if (level.solutionAt(r, c)) {
        _grid[r][c] = CellMark.brick;
        _bricksLaid++;
        final won = _checkComplete();
        notifyListeners();
        return won ? TapResult.completedRound : TapResult.placed;
      }
      _mistakes++;
      _grid[r][c] = CellMark.cross;
      flashRow = r;
      flashCol = c;
      if (_mistakes >= level.lives) {
        _status = BlueprintStatus.scrapped;
        notifyListeners();
        return TapResult.scrappedRound;
      }
      notifyListeners();
      return TapResult.mistake;
    } else {
      _grid[r][c] = CellMark.cross;
      notifyListeners();
      return TapResult.marked;
    }
  }

  /// True if every solution brick in row [r] is already laid.
  bool rowSatisfied(int r) {
    for (var c = 0; c < cols; c++) {
      if (level.solutionAt(r, c) && _grid[r][c] != CellMark.brick) return false;
    }
    return true;
  }

  /// True if every solution brick in column [c] is already laid.
  bool colSatisfied(int c) {
    for (var r = 0; r < rows; r++) {
      if (level.solutionAt(r, c) && _grid[r][c] != CellMark.brick) return false;
    }
    return true;
  }

  /// Reveals one correct, not-yet-laid brick. Returns false if none remain.
  bool useHint() {
    if (!isInteractive) return false;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (level.solutionAt(r, c) && _grid[r][c] != CellMark.brick) {
          _grid[r][c] = CellMark.brick;
          _bricksLaid++;
          _hintsUsed++;
          final won = _checkComplete();
          if (won) _status = BlueprintStatus.complete;
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  /// Grants one extra life (Reinforcement power-up) after a scrap.
  void reviveWithExtraLife() {
    if (_status != BlueprintStatus.scrapped) return;
    _mistakes = (level.lives - 1).clamp(0, level.lives);
    _status = BlueprintStatus.building;
    notifyListeners();
  }

  bool _checkComplete() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (level.solutionAt(r, c) && _grid[r][c] != CellMark.brick) {
          return false;
        }
      }
    }
    _status = BlueprintStatus.complete;
    return true;
  }
}

enum TapResult {
  ignored,
  placed,
  removed,
  marked,
  mistake,
  scrappedRound,
  completedRound,
}
