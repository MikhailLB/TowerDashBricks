import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'core/white_part.dart';
import 'game/level_config.dart';
import 'gate/infra/brick_beacon.dart';
import 'gate/infra/brick_dispatch.dart';
import 'gate/infra/network_probe.dart';
import 'gate/infra/brick_vault.dart';
import 'gate/infra/brick_signal.dart';
import 'gate/pages/brick_gate_loader.dart';
import 'screens/game_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';

// ════════════════════════════════════════════════════════════
// TowerDashGateApp — root widget
// ════════════════════════════════════════════════════════════
//
// All white-part game routes MUST be registered in the routes: map.
// If the game uses named routes, they must exist here or the app
// will crash with "Could not find route RouteSettings('/menu', null)".
// ════════════════════════════════════════════════════════════
class TowerDashGateApp extends StatelessWidget {
  final BrickVault vault;
  final NetworkProbe probe;
  final BrickSignal signal;
  final BrickDispatch dispatch;
  final BrickBeacon beacon;
  final bool gateEnabled;

  const TowerDashGateApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.beacon,
    required this.gateEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? BrickGateLoader(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            beacon: beacon,
          )
        : const WhiteGameEntry();

    return MaterialApp(
      title: 'TowerDash Bricks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        // Black scaffold prevents background bleed on cold-start WebView launch.
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.craneYellow,
          brightness: Brightness.dark,
        ),
      ),
      home: home,
      routes: {
        // ── TowerDash Bricks white-part named routes ──────────
        '/loading':      (_) => const LoadingScreen(),
        '/menu':         (_) => const MainMenuScreen(),
        '/level-select': (_) => const LevelSelectScreen(),
        // GameScreen always receives levelConfig from LevelSelectScreen via
        // MaterialPageRoute — this named route fallback uses level 1 defaults.
        '/game':         (_) => GameScreen(levelConfig: levels.first),
        '/settings':     (_) => const SettingsScreen(),
        '/shop':         (_) => const ShopScreen(),
      },
    );
  }
}
