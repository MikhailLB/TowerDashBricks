import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/main_menu_screen.dart';

///
/// TdbLoader routes here after resolving the user as "game" mode.
/// Skips LoadingScreen to avoid a double splash — the gate already showed
/// its own splash video in TdbLoader.
class TdbGameRoot extends StatefulWidget {
  const TdbGameRoot({super.key});

  @override
  State<TdbGameRoot> createState() => _WhiteGameEntryState();
}

class _WhiteGameEntryState extends State<TdbGameRoot> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) => const MainMenuScreen();
}
