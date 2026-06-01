import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/puzzle_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/blueprint_background.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pixel_button.dart';
import 'info_web_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _showHowTo = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    progress.addListener(_onProgressChanged);
    AudioService.instance.playBgm(Bgm.menu);
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// The next puzzle the player hasn't completed yet (or the last one).
  PuzzleLevel get _featured {
    for (final l in puzzleLevels) {
      if (!progress.isLevelCompleted(l.levelNumber)) return l;
    }
    return puzzleLevels.last;
  }

  Future<void> _openLevelSelect() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LevelSelectScreen()),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  Future<void> _openShop() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
    );
  }

  Future<void> _openSettings() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _openPrivacy() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const InfoWebScreen(
          title: 'Privacy Policy',
          url: 'https://towerdashbriicks.com/privacy-policy.html',
        ),
      ),
    );
  }

  Future<void> _openSupport() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const InfoWebScreen(
          title: 'Support',
          url: 'https://towerdashbriicks.com/support.html',
        ),
      ),
    );
  }

  void _openHowTo() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() => _showHowTo = true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final total = puzzleLevels.length;
    final solved = progress.completedLevels.length;

    return Scaffold(
      body: Stack(
        children: [
          BlueprintBackground(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          _StatChip(
                            icon: Icons.verified_rounded,
                            label: 'Solved',
                            value: '$solved/$total',
                          ),
                          const Spacer(),
                          _StatChip(
                            icon: Icons.toll_rounded,
                            label: 'Coins',
                            value: '${progress.coins}',
                          ),
                          const SizedBox(width: 10),
                          _CircleAction(
                            icon: Icons.settings_rounded,
                            onTap: _openSettings,
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Column(
                        children: [
                          Image.asset(
                            TdbAssets.gameName,
                            width: size.width * 0.7,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.craneYellow
                                      .withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'NONOGRAM BLUEPRINTS',
                              style: AppTextStyles.body(
                                      size: 11, color: AppColors.craneYellow)
                                  .copyWith(letterSpacing: 3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Featured blueprint card — scales down so it never
                    // overflows on small screens.
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _FeaturedCard(
                              level: _featured,
                              completed: progress
                                  .isLevelCompleted(_featured.levelNumber),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelButton(
                            label: 'Build',
                            onPressed: _openLevelSelect,
                            width: double.infinity,
                            height: 64,
                            fontSize: 26,
                            icon: Icons.architecture_rounded,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: PixelButton(
                                  label: 'Shop',
                                  onPressed: _openShop,
                                  width: double.infinity,
                                  height: 50,
                                  fontSize: 18,
                                  color: PixelButtonColor.secondary,
                                  icon: Icons.storefront_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PixelButton(
                                  label: 'How to Play',
                                  onPressed: _openHowTo,
                                  width: double.infinity,
                                  height: 50,
                                  fontSize: 16,
                                  color: PixelButtonColor.secondary,
                                  icon: Icons.help_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LinkBtn(
                                  label: 'Privacy Policy',
                                  onTap: _openPrivacy),
                              const Text('·',
                                  style: TextStyle(color: Colors.white38)),
                              _LinkBtn(label: 'Support', onTap: _openSupport),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showHowTo)
            HowToPlayOverlay(
              onClose: () => setState(() => _showHowTo = false),
            ),
        ],
      ),
    );
  }
}

/// A blueprint "sheet" for the next job. The picture stays sealed until the
/// puzzle is solved — no spoilers.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.level, required this.completed});
  final PuzzleLevel level;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2335).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.craneYellow.withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                completed ? 'REPLAY' : 'NEXT JOB',
                style:
                    AppTextStyles.body(size: 10, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 2),
              ),
              Text('#${level.levelNumber}',
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 116,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF081320),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            // Only reveal the picture once it's been solved.
            child: completed
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: BlueprintThumbnail(rowsArt: level.rowsArt, size: 80),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.architecture_rounded,
                          size: 34,
                          color:
                              AppColors.craneYellow.withValues(alpha: 0.6)),
                      const SizedBox(height: 4),
                      Text('SEALED',
                          style: AppTextStyles.body(
                                  size: 10, color: AppColors.textMuted)
                              .copyWith(letterSpacing: 2)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Text(completed ? level.name : 'Blueprint ${level.levelNumber}',
              style: AppTextStyles.title(size: 22)),
          const SizedBox(height: 2),
          Text('${level.colCount}×${level.rowCount} grid · ${level.lives} lives',
              style: AppTextStyles.body(size: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.craneYellow, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style:
                      AppTextStyles.body(size: 10, color: AppColors.textMuted)
                          .copyWith(letterSpacing: 0.8)),
              Text(value,
                  style:
                      AppTextStyles.button(size: 15, color: AppColors.text)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Icon(icon, color: AppColors.text, size: 24),
      ),
    );
  }
}

class _LinkBtn extends StatelessWidget {
  const _LinkBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          style: AppTextStyles.body(size: 12, color: AppColors.textMuted)
              .copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
