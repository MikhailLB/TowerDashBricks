import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tdb_assets.dart';

/// Warms Flame image cache for gameplay sprites.
///
/// LoadingScreen does this on the white branch. Gray flow skips LoadingScreen
/// (BrickGateLoader → MainMenuScreen), so we must preload during app boot.
Future<void> preloadGameAssets() async {
  Flame.images.prefix = '';

  final paths = <String>[
    TdbAssets.sky,
    TdbAssets.ground,
    TdbAssets.cloud,
    TdbAssets.crane,
    TdbAssets.cityBg,
    TdbAssets.base,
    TdbAssets.icon,
    TdbAssets.gameName,
    ...TdbAssets.allBricks,
    for (var i = 1; i <= 4; i++) TdbAssets.loadingBar(i),
  ];

  for (final path in paths) {
    try {
      await Flame.images.load(path);
    } catch (e) {
      debugPrint('[ASSETS] failed to preload $path: $e');
    }
  }

  try {
    GoogleFonts.robotoSlab();
    await GoogleFonts.pendingFonts(<TextStyle>[
      GoogleFonts.robotoSlab(),
    ]);
  } catch (e) {
    debugPrint('[ASSETS] Google Fonts preload failed: $e');
  }
}
