import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Daytime construction palette for Tower Dash Bricks.
///
/// Constant names are preserved from the legacy project so existing widgets
/// keep compiling, but values are remapped to a bright "build site" look:
/// blue sky, warm crane yellow / orange accents, glassy dark-navy panels that
/// read well on top of the parallax background image.
class AppColors {
  // Backdrop (used as fallback behind the parallax image)
  static const background = Color(0xFF132A4A);
  static const concrete = Color(0xFF14213D);

  // Brick accents -> warm construction tones
  static const brickRed = Color(0xFFE8552F);
  static const rust = Color(0xFFB5471F);

  // Primary accent -> sky blue
  static const craneYellow = Color(0xFFFFC83D);

  // Secondary accent -> plasma orange
  static const accent = Color(0xFFFF8A3D);
  static const accentDeep = Color(0xFFC75A0A);

  // UI panels — glassy navy
  static const panel = Color(0xCC10203A);
  static const panelSolid = Color(0xFF12233F);
  static const panelLight = Color(0xFF1B3157);
  static const card = Color(0xFF0E1B30);
  static const cardBorder = Color(0xFF2C456E);

  // Text
  static const text = Color(0xFFEAF1FF);
  static const textMuted = Color(0xFF93A6C9);
  static const textDark = Color(0xFF09182B);

  // Status
  static const danger = Color(0xFFFF4E54);
  static const success = Color(0xFF35C46A);
  static const timerWarning = Color(0xFFFFC83D);
  static const timerDanger = Color(0xFFFF4E54);

  // Gradients / sky
  static const sky = background;
  static const menuBgTop = Color(0xFF1E4E86);
  static const menuBgBottom = Color(0xFF49A6E0);

  // Secondary-button (steel blue)
  static const btnSecTop = Color(0xFF2C456E);
  static const btnSecBottom = Color(0xFF0E1B30);
  static const btnSecBorder = Color(0xFF4E78B8);

  // Combo / streak colors
  static const combo2x = Color(0xFF2FA4FF);
  static const combo3x = Color(0xFFFFC83D);

  // Primary semantic accents (used widely across screens)
  static const neonCyan = Color(0xFF2FA4FF); // primary blue
  static const neonViolet = Color(0xFF8B6CE8);
  static const neonGold = Color(0xFFFFC83D);
  static const neonMagenta = Color(0xFFFF5C8A);
  static const starWhite = Color(0xFFFFFFFF);

  // ── Brick-unit suit / rarity colors ─────────────────────────────────
  static const tank = Color(0xFF9AA7B8);
  static const warrior = Color(0xFFE8552F);
  static const archer = Color(0xFF2FA4FF);
  static const mage = Color(0xFF8B6CE8);
  static const healer = Color(0xFF35C46A);
  static const bomber = Color(0xFFFF8A3D);
  static const golem = Color(0xFF8A6A3B);
  static const sniper = Color(0xFF2E8C82);

  static const rarityCommon = Color(0xFFA9B6C7);
  static const rarityRare = Color(0xFF3FA9FF);
  static const rarityEpic = Color(0xFFB46BFF);
  static const rarityLegendary = Color(0xFFFFC23D);
}

class AppTextStyles {
  static TextStyle title({double size = 38, Color color = AppColors.text}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        shadows: const [
          Shadow(blurRadius: 14, color: Color(0xAA000000), offset: Offset(0, 4)),
        ],
      );

  static TextStyle button({double size = 22, Color color = AppColors.text}) =>
      GoogleFonts.exo2(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      );

  static TextStyle body({double size = 16, Color color = AppColors.text}) =>
      GoogleFonts.exo2(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w400,
      );

  static TextStyle score({double size = 28, Color color = AppColors.text}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(blurRadius: 8, color: Color(0xCC000000), offset: Offset(2, 2)),
        ],
      );

  static TextStyle headline(
          {double size = 48, Color color = AppColors.craneYellow}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        shadows: const [
          Shadow(blurRadius: 18, color: Color(0x88000000), offset: Offset(0, 3)),
        ],
      );
}
