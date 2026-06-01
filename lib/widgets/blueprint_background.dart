import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// A reusable "architect blueprint" backdrop: deep navy wash with fine
/// graph-paper lines and a few accent rules. Gives the puzzle game its own
/// identity, distinct from the old city-photo menu.
class BlueprintBackground extends StatelessWidget {
  const BlueprintBackground({
    super.key,
    this.child,
    this.cell = 26,
    this.vignette = true,
  });

  final Widget? child;
  final double cell;
  final bool vignette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2038), Color(0xFF0A1828), Color(0xFF081320)],
        ),
      ),
      child: CustomPaint(
        painter: _BlueprintPainter(cell: cell, vignette: vignette),
        child: child,
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter({required this.cell, required this.vignette});

  final double cell;
  final bool vignette;

  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.6;
    final bold = Paint()
      ..color = AppColors.craneYellow.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    var i = 0;
    for (var x = 0.0; x <= size.width; x += cell, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          i % 5 == 0 ? bold : fine);
    }
    i = 0;
    for (var y = 0.0; y <= size.height; y += cell, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          i % 5 == 0 ? bold : fine);
    }

    if (vignette) {
      final v = Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF050C16).withValues(alpha: 0.6)],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, v);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) =>
      oldDelegate.cell != cell || oldDelegate.vignette != vignette;
}

/// Renders a puzzle solution as a small monochrome silhouette — used as a
/// "blueprint thumbnail" on level cards and previews.
class BlueprintThumbnail extends StatelessWidget {
  const BlueprintThumbnail({
    super.key,
    required this.rowsArt,
    required this.size,
    this.brickColor = AppColors.craneYellow,
    this.locked = false,
  });

  final List<String> rowsArt;
  final double size;
  final Color brickColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ThumbPainter(
          rowsArt: rowsArt,
          color: locked ? Colors.white24 : brickColor,
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter({required this.rowsArt, required this.color});

  final List<String> rowsArt;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (rowsArt.isEmpty) return;
    final rows = rowsArt.length;
    final cols = rowsArt.first.length;
    final cell = (size.width / cols).clamp(0.0, size.height / rows);
    final gridW = cell * cols;
    final gridH = cell * rows;
    final ox = (size.width - gridW) / 2;
    final oy = (size.height - gridH) / 2;

    final fill = Paint()..color = color;
    final gap = Paint()..color = Colors.white.withValues(alpha: 0.05);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          ox + c * cell + 0.5,
          oy + r * cell + 0.5,
          cell - 1,
          cell - 1,
        );
        canvas.drawRect(rect, rowsArt[r][c] == '#' ? fill : gap);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rowsArt != rowsArt;
}
