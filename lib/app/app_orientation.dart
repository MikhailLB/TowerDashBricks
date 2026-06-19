import 'package:flutter/services.dart';

/// Loading splash supports all four orientations so both portrait and
/// landscape splash videos can play correctly.
Future<void> setOrientationsForLoadingScreens() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Gameplay and all menus are locked to portrait on both phones and iPads.
Future<void> setOrientationsLockedPortrait() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}
