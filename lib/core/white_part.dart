import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';

/// Entry point into the TowerDash Bricks game from the gray gate.
/// BrickGateLoader navigates here when the backend decides the user is organic.
/// Do NOT add any gate/ imports in this file or in the game code.
class WhiteGameEntry extends StatelessWidget {
  const WhiteGameEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate directly to MainMenuScreen — BrickGateLoader already served as
    // the loading experience. Returning LoadingScreen would cause a double
    // loading animation (known issue documented in gray_flow_guide.md).
    return const MainMenuScreen();
  }
}
