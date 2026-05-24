import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark-industrial background
  static const background = Color(0xFF0D1B2A);
  static const concrete = Color(0xFF1E2D3D);

  // Brick red & rust
  static const brickRed = Color(0xFF8B3A2F);
  static const rust = Color(0xFFB04A1E);

  // Construction yellow / orange
  static const craneYellow = Color(0xFFF5A623);
  static const accent = Color(0xFFD4541A);
  static const accentDeep = Color(0xFF9C3A0E);

  // UI panels
  static const panel = Color(0xCC1E2D3D);
  static const panelSolid = Color(0xFF1E2D3D);
  static const panelLight = Color(0xFF2A3D52);
  static const card = Color(0xFF162230);
  static const cardBorder = Color(0xFF2D4A62);

  // Text
  static const text = Color(0xFFF5F0E8);
  static const textMuted = Color(0xFF8A9BAB);
  static const textDark = Color(0xFF0D1B2A);

  // Status
  static const danger = Color(0xFFE84545);
  static const success = Color(0xFF2ECC71);
  static const timerWarning = Color(0xFFFFB700);
  static const timerDanger = Color(0xFFE84545);

  // Gradients
  static const sky = background;
  static const menuBgTop = Color(0xFF0A1520);
  static const menuBgBottom = Color(0xFF1A2D42);

  // Button secondary (steel blue)
  static const btnSecTop = Color(0xFF2D4A62);
  static const btnSecBottom = Color(0xFF162230);
  static const btnSecBorder = Color(0xFF4A7090);

  // Combo colors
  static const combo2x = Color(0xFFF5A623);
  static const combo3x = Color(0xFFE84545);
}

class AppTextStyles {
  /// Big display title — Roboto Slab ExtraBold
  static TextStyle title({double size = 38, Color color = AppColors.text}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        shadows: const [
          Shadow(blurRadius: 14, color: Color(0xAA000000), offset: Offset(0, 4)),
        ],
      );

  /// Buttons & labels — Roboto Slab Bold
  static TextStyle button({double size = 22, Color color = AppColors.text}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  /// Body / subtitles — Roboto Slab Regular
  static TextStyle body({double size = 16, Color color = AppColors.text}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w400,
      );

  /// Score / HUD — Roboto Slab Black
  static TextStyle score({double size = 28, Color color = AppColors.text}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        shadows: const [
          Shadow(blurRadius: 8, color: Color(0xCC000000), offset: Offset(2, 2)),
        ],
      );

  /// Headline accent — Roboto Slab Black in crane-yellow
  static TextStyle headline(
          {double size = 48, Color color = AppColors.craneYellow}) =>
      GoogleFonts.robotoSlab(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: const [
          Shadow(blurRadius: 16, color: Color(0xAAD4541A), offset: Offset(0, 2)),
        ],
      );
}
