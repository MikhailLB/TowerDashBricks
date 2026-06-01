import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/nonogram_controller.dart';

/// Renders the blueprint grid with row/column clues and forwards taps & drags.
/// Pure Flutter — sizes itself to the available space and keeps cells square.
/// The grid frame is drawn with [foregroundDecoration] so it never affects
/// layout size (avoids overflow).
class BlueprintGrid extends StatefulWidget {
  const BlueprintGrid({
    super.key,
    required this.controller,
    required this.brickAsset,
    required this.onCellTap,
    required this.onCellDrag,
    required this.onDragStart,
  });

  final NonogramController controller;
  final String brickAsset;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellDrag;
  final VoidCallback onDragStart;

  @override
  State<BlueprintGrid> createState() => _BlueprintGridState();
}

class _BlueprintGridState extends State<BlueprintGrid> {
  int? _lastDragRow;
  int? _lastDragCol;

  int get _maxRowClueLen => widget.controller.level.rowClues
      .map((e) => e.length)
      .fold(1, (a, b) => math.max(a, b));

  int get _maxColClueLen => widget.controller.level.colClues
      .map((e) => e.length)
      .fold(1, (a, b) => math.max(a, b));

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final rows = controller.rows;
    final cols = controller.cols;
    final leftUnits = _maxRowClueLen + 0.5;
    final topUnits = _maxColClueLen + 0.5;
    const frame = 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = math.min(
          (constraints.maxWidth - frame * 2) / (cols + leftUnits),
          (constraints.maxHeight - frame * 2) / (rows + topUnits),
        );
        final gridW = cell * cols;
        final gridH = cell * rows;
        final leftGutter = cell * leftUnits;
        final topGutter = cell * topUnits;

        return Center(
          child: SizedBox(
            width: leftGutter + gridW + frame * 2,
            height: topGutter + gridH + frame * 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: corner spacer + column clues
                SizedBox(
                  height: topGutter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(width: leftGutter + frame, height: topGutter),
                      for (var c = 0; c < cols; c++)
                        _ColumnClue(
                          clues: controller.level.colClues[c],
                          size: cell,
                          height: topGutter,
                          emphasized: (c + 1) % 5 == 0,
                          dim: controller.colSatisfied(c),
                        ),
                    ],
                  ),
                ),
                // Body: row clues + cells
                Row(
                  children: [
                    SizedBox(
                      width: leftGutter,
                      height: gridH + frame * 2,
                      child: Padding(
                        padding: const EdgeInsets.only(top: frame),
                        child: Column(
                          children: [
                            for (var r = 0; r < rows; r++)
                              _RowClue(
                                clues: controller.level.rowClues[r],
                                size: cell,
                                width: leftGutter,
                                emphasized: (r + 1) % 5 == 0,
                                dim: controller.rowSatisfied(r),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildCells(cell, gridW, gridH, frame),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCells(double cell, double gridW, double gridH, double frame) {
    final controller = widget.controller;
    final rows = controller.rows;
    final cols = controller.cols;

    void handleAt(Offset local, {required bool isTap}) {
      final c = (local.dx / cell).floor().clamp(0, cols - 1);
      final r = (local.dy / cell).floor().clamp(0, rows - 1);
      if (isTap) {
        widget.onCellTap(r, c);
      } else {
        if (_lastDragRow == r && _lastDragCol == c) return;
        _lastDragRow = r;
        _lastDragCol = c;
        widget.onCellDrag(r, c);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => handleAt(d.localPosition, isTap: true),
      onPanStart: (d) {
        widget.onDragStart();
        _lastDragRow = null;
        _lastDragCol = null;
        handleAt(d.localPosition, isTap: false);
      },
      onPanUpdate: (d) => handleAt(d.localPosition, isTap: false),
      onPanEnd: (_) {
        _lastDragRow = null;
        _lastDragCol = null;
      },
      child: Container(
        width: gridW + frame * 2,
        height: gridH + frame * 2,
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.8),
            width: frame,
          ),
        ),
        decoration: const BoxDecoration(color: AppColors.card),
        padding: EdgeInsets.all(frame),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < cols; c++)
                    _Cell(
                      mark: controller.cellAt(r, c),
                      brickAsset: widget.brickAsset,
                      size: cell,
                      flashing:
                          controller.flashRow == r && controller.flashCol == c,
                      rightHeavy: (c + 1) % 5 == 0 && c != cols - 1,
                      bottomHeavy: (r + 1) % 5 == 0 && r != rows - 1,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.mark,
    required this.brickAsset,
    required this.size,
    required this.flashing,
    required this.rightHeavy,
    required this.bottomHeavy,
  });

  final CellMark mark;
  final String brickAsset;
  final double size;
  final bool flashing;
  final bool rightHeavy;
  final bool bottomHeavy;

  @override
  Widget build(BuildContext context) {
    final lineColor = Colors.white.withValues(alpha: 0.10);
    final heavyColor = AppColors.craneYellow.withValues(alpha: 0.35);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: flashing
            ? AppColors.danger.withValues(alpha: 0.55)
            : (mark == CellMark.brick
                ? null
                : AppColors.card.withValues(alpha: 0.4)),
        border: Border(
          right: BorderSide(
            color: rightHeavy ? heavyColor : lineColor,
            width: rightHeavy ? 1.5 : 0.5,
          ),
          bottom: BorderSide(
            color: bottomHeavy ? heavyColor : lineColor,
            width: bottomHeavy ? 1.5 : 0.5,
          ),
        ),
      ),
      child: _content(),
    );
  }

  Widget _content() {
    switch (mark) {
      case CellMark.brick:
        return Padding(
          padding: EdgeInsets.all(size * 0.04),
          child:
              Image.asset(brickAsset, fit: BoxFit.fill, gaplessPlayback: true),
        );
      case CellMark.cross:
        return Center(
          child: Icon(
            Icons.close_rounded,
            size: size * 0.55,
            color: AppColors.textMuted.withValues(alpha: 0.75),
          ),
        );
      case CellMark.empty:
        return const SizedBox.shrink();
    }
  }
}

class _RowClue extends StatelessWidget {
  const _RowClue({
    required this.clues,
    required this.size,
    required this.width,
    required this.emphasized,
    required this.dim,
  });

  final List<int> clues;
  final double size;
  final double width;
  final bool emphasized;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final visible = clues.where((e) => e > 0).toList();
    return SizedBox(
      width: width,
      height: size,
      child: Padding(
        padding: EdgeInsets.only(right: size * 0.2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visible.isEmpty)
                _ClueNumber(value: 0, size: size, emphasized: emphasized, dim: dim)
              else
                for (final n in visible) ...[
                  _ClueNumber(
                      value: n, size: size, emphasized: emphasized, dim: dim),
                  SizedBox(width: size * 0.24),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnClue extends StatelessWidget {
  const _ColumnClue({
    required this.clues,
    required this.size,
    required this.height,
    required this.emphasized,
    required this.dim,
  });

  final List<int> clues;
  final double size;
  final double height;
  final bool emphasized;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final visible = clues.where((e) => e > 0).toList();
    return SizedBox(
      width: size,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(bottom: size * 0.16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visible.isEmpty)
                _ClueNumber(value: 0, size: size, emphasized: emphasized, dim: dim)
              else
                for (final n in visible) ...[
                  _ClueNumber(
                      value: n, size: size, emphasized: emphasized, dim: dim),
                  SizedBox(height: size * 0.13),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClueNumber extends StatelessWidget {
  const _ClueNumber({
    required this.value,
    required this.size,
    required this.emphasized,
    required this.dim,
  });

  final int value;
  final double size;
  final bool emphasized;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final base =
        emphasized ? AppColors.craneYellow : AppColors.text;
    return Text(
      '$value',
      style: AppTextStyles.button(
        size: size * 0.5,
        color: dim ? base.withValues(alpha: 0.25) : base,
      ),
    );
  }
}
