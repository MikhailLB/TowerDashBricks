import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/tdb_assets.dart';

/// Full-bleed construction-site backdrop: a sky image with a ground strip
/// anchored to the bottom and soft gradient scrims for text contrast.
class BrickBackground extends StatelessWidget {
  const BrickBackground({
    super.key,
    required this.child,
    this.skyAsset = TdbAssets.sky,
    this.showGround = true,
    this.dim = 0.0,
  });

  final Widget child;
  final String skyAsset;
  final bool showGround;

  /// Extra darkening (0..1) over the whole scene.
  final double dim;

  @override
  Widget build(BuildContext context) {
    // Some backgrounds already bake in their own ground strip; avoid drawing
    // the shared ground sprite on top of those.
    final drawGround =
        showGround && !TdbAssets.backgroundsWithGround.contains(skyAsset);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fallback color in case the image is still decoding.
        const ColoredBox(color: AppColors.background),
        Image.asset(skyAsset, fit: BoxFit.cover, gaplessPlayback: true),
        if (drawGround)
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              TdbAssets.ground,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              gaplessPlayback: true,
            ),
          ),
        // Top scrim so status bar / titles stay readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x66000000), Color(0x00000000)],
            ),
          ),
        ),
        // Vignette for depth.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [Color(0x00000000), Color(0x55000000)],
              stops: [0.62, 1.0],
            ),
          ),
        ),
        if (dim > 0)
          ColoredBox(color: Colors.black.withValues(alpha: dim.clamp(0, 1))),
        child,
      ],
    );
  }
}
