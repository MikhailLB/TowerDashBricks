import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'core/tdb_game_root.dart';
import 'hub/infra/tdb_push.dart';
import 'hub/infra/tdb_request.dart';
import 'hub/infra/tdb_net.dart';
import 'hub/infra/tdb_store.dart';
import 'hub/infra/tdb_attr.dart';
import 'hub/views/tdb_loader.dart';

class TdbApp extends StatelessWidget {
  final TdbStore vault;
  final TdbNet probe;
  final TdbAttr signal;
  final TdbRequest dispatch;
  final TdbPush beacon;
  final bool tdbHubActive;

  const TdbApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.beacon,
    required this.tdbHubActive,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = tdbHubActive
        ? TdbLoader(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            beacon: beacon,
          )
        : const TdbGameRoot();

    return MaterialApp(
      title: 'TowerDash Bricks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.craneYellow,
          brightness: Brightness.dark,
        ),
      ),
      home: home,
    );
  }
}
