import 'package:flutter/material.dart';

import '../app/app_theme.dart';

enum PixelButtonColor { primary, secondary, danger }

/// Industrial-style game button with brick-red/yellow gradient, glow, and press animation.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 220,
    this.height = 60,
    this.fontSize = 22,
    this.color = PixelButtonColor.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;
  final PixelButtonColor color;
  final IconData? icon;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _ctrl.forward();
  }

  void _up() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    Color topGrad, botGrad, topPress, botPress, borderCol, glowCol;
    switch (widget.color) {
      case PixelButtonColor.primary:
        topGrad = AppColors.craneYellow;
        botGrad = AppColors.accent;
        topPress = const Color(0xFFCC8A00);
        botPress = AppColors.accentDeep;
        borderCol = AppColors.rust.withValues(alpha: 0.8);
        glowCol = AppColors.craneYellow.withValues(alpha: 0.3);
        break;
      case PixelButtonColor.secondary:
        topGrad = AppColors.btnSecTop;
        botGrad = AppColors.btnSecBottom;
        topPress = const Color(0xFF1E3448);
        botPress = const Color(0xFF0A1520);
        borderCol = AppColors.btnSecBorder.withValues(alpha: 0.8);
        glowCol = AppColors.btnSecBorder.withValues(alpha: 0.2);
        break;
      case PixelButtonColor.danger:
        topGrad = const Color(0xFFE84545);
        botGrad = const Color(0xFF9C2020);
        topPress = const Color(0xFFB03030);
        botPress = const Color(0xFF6E1515);
        borderCol = const Color(0xFFE84545).withValues(alpha: 0.7);
        glowCol = const Color(0xFFE84545).withValues(alpha: 0.25);
        break;
    }

    final radius = BorderRadius.circular(widget.height * 0.32);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) {
        _up();
        widget.onPressed?.call();
      },
      onTapCancel: _up,
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = _ctrl.value;
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(topGrad, topPress, t)!,
                      Color.lerp(botGrad, botPress, t)!,
                    ],
                  ),
                  border: Border.all(color: borderCol, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: glowCol,
                      blurRadius: 12 * (1 - t * 0.8),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: Offset(0, 4 * (1 - t * 0.7)),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rivet / shine accent on top
                    Positioned(
                      top: 3,
                      left: 8,
                      right: 8,
                      height: widget.height * 0.32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(widget.height * 0.30),
                            bottom: Radius.circular(2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(
                                  alpha: 0.18 * (1 - t * 0.9)),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              color: Colors.white,
                              size: widget.fontSize * 1.1),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.button(
                            size: widget.fontSize,
                            color: Colors.white,
                          ).copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.65),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
