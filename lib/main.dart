import 'package:flutter/material.dart';

import 'app/app_orientation.dart';
import 'app/app_theme.dart';
import 'screens/loading_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/game_progress.dart';

late final GameProgress progress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setOrientationsForLoadingScreens();

  final storage = await StorageService.create();
  progress = GameProgress(storage);

  await AudioService.init(progress);

  runApp(const TowerDashBricksApp());
}

class TowerDashBricksApp extends StatelessWidget {
  const TowerDashBricksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Dash Bricks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.craneYellow,
          brightness: Brightness.dark,
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
