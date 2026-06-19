import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/unit_class.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pixel_button.dart';
import '../widgets/unit_sprite.dart';
import 'info_web_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'arena_screen.dart';
import 'campaign_map_screen.dart';
import 'collection_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _bobCtrl;
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
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    progress.addListener(_onProgressChanged);
    AudioService.instance.playBgm(Bgm.menu);
    if (!progress.tutorialSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showHowTo = true);
      });
    }
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    _fadeCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen, {bool menuBgmOnReturn = true}) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted && menuBgmOnReturn) AudioService.instance.playBgm(Bgm.menu);
  }

  Future<void> _openInfo(String title, String url) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InfoWebScreen(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BrickBackground(
            skyAsset: TdbAssets.bgSunset,
            showGround: false,
            dim: 0.08,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          _CurrencyChip(
                            icon: Icons.toll_rounded,
                            color: AppColors.neonGold,
                            value: '${progress.coins}',
                          ),
                          const SizedBox(width: 8),
                          _CurrencyChip(
                            icon: Icons.diamond_rounded,
                            color: AppColors.archer,
                            value: '${progress.gems}',
                          ),
                          const Spacer(),
                          _CircleAction(
                            icon: Icons.settings_rounded,
                            onTap: () => _open(const SettingsScreen()),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Column(
                        children: [
                          Image.asset(
                            TdbAssets.gameName,
                            width: MediaQuery.of(context).size.width * 0.72,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              border: Border.all(
                                  color: AppColors.craneYellow
                                      .withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('BRICK TACTICS',
                                style: AppTextStyles.body(
                                        size: 11, color: AppColors.craneYellow)
                                    .copyWith(letterSpacing: 4)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _MenuScene(bob: _bobCtrl),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelButton(
                            label: 'Campaign',
                            icon: Icons.flag_rounded,
                            width: double.infinity,
                            height: 64,
                            fontSize: 24,
                            onPressed: () =>
                                _open(const CampaignMapScreen()),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: PixelButton(
                                  label: 'Arena',
                                  icon: Icons.sports_mma_rounded,
                                  width: double.infinity,
                                  height: 56,
                                  fontSize: 18,
                                  color: PixelButtonColor.secondary,
                                  onPressed: () => _open(const ArenaScreen()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    PixelButton(
                                      label: 'Collection',
                                      icon: Icons.dashboard_customize_rounded,
                                      width: double.infinity,
                                      height: 56,
                                      fontSize: 18,
                                      color: PixelButtonColor.secondary,
                                      onPressed: () =>
                                          _open(const CollectionScreen()),
                                    ),
                                    if (progress.hasUnseenLevelUps)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.white, width: 1.5),
                                          ),
                                          child: Text('LV UP',
                                              style: AppTextStyles.body(
                                                  size: 9, color: Colors.white)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: PixelButton(
                                  label: 'Shop',
                                  icon: Icons.storefront_rounded,
                                  width: double.infinity,
                                  height: 52,
                                  fontSize: 18,
                                  color: PixelButtonColor.secondary,
                                  onPressed: () => _open(const ShopScreen(),
                                      menuBgmOnReturn: false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PixelButton(
                                  label: 'How to Play',
                                  icon: Icons.help_outline_rounded,
                                  width: double.infinity,
                                  height: 52,
                                  fontSize: 16,
                                  color: PixelButtonColor.secondary,
                                  onPressed: () {
                                    AudioService.instance
                                        .playSfx(Sfx.buttonClick);
                                    setState(() => _showHowTo = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LinkBtn(
                                label: 'Privacy Policy',
                                onTap: () => _openInfo('Privacy Policy',
                                    'https://towerdashbriicks.com/privacy-policy.html'),
                              ),
                              const Text('·',
                                  style: TextStyle(color: Colors.white38)),
                              _LinkBtn(
                                label: 'Support',
                                onTap: () => _openInfo('Support',
                                    'https://towerdashbriicks.com/support.html'),
                              ),
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
              onClose: () {
                setState(() => _showHowTo = false);
                progress.setTutorialSeen();
              },
            ),
        ],
      ),
    );
  }
}

/// A small animated diorama for the menu: a crane lifting a brick over a
/// little squad of brick heroes, so the start screen feels alive.
class _MenuScene extends StatelessWidget {
  const _MenuScene({required this.bob});
  final Animation<double> bob;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final unit = (c.maxWidth * 0.16).clamp(42.0, 70.0).toDouble();
          final brick = (c.maxWidth * 0.16).clamp(40.0, 66.0).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating building blocks drifting in the sky.
              _floatBrick(0, brick, bob, 0.0,
                  left: c.maxWidth * 0.06, top: c.maxHeight * 0.02),
              _floatBrick(2, brick * 0.85, bob, 0.5,
                  left: c.maxWidth * 0.74, top: c.maxHeight * 0.0),
              _floatBrick(4, brick * 0.7, bob, 0.25,
                  left: c.maxWidth * 0.46, top: c.maxHeight * 0.16),
              // Crane + squad lined up on the ground, no overlaps.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedBuilder(
                        animation: bob,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, bob.value * 4 - 2),
                          child: child,
                        ),
                        child: Image.asset(TdbAssets.crane,
                            width: unit * 2.1, gaplessPlayback: true),
                      ),
                      SizedBox(width: unit * 0.45),
                      _hero(UnitClass.tank, unit * 0.92, bob, 0.0),
                      _hero(UnitClass.warrior, unit, bob, 0.4),
                      _hero(UnitClass.archer, unit * 1.02, bob, 0.15),
                      _hero(UnitClass.mage, unit * 0.95, bob, 0.6),
                      _hero(UnitClass.golem, unit * 0.92, bob, 0.3),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _floatBrick(
      int sprite, double size, Animation<double> bob, double phase,
      {required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: bob,
        builder: (context, child) {
          final v = (bob.value + phase) % 1.0;
          final dy = math.sin(v * math.pi * 2) * 7;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Opacity(
          opacity: 0.92,
          child: Image.asset(TdbAssets.buildingFloor(sprite),
              width: size, gaplessPlayback: true),
        ),
      ),
    );
  }

  Widget _hero(
      UnitClass clazz, double size, Animation<double> bob, double phase) {
    return AnimatedBuilder(
      animation: bob,
      builder: (context, child) {
        final v = (bob.value + phase) % 1.0;
        final dy = math.sin(v * math.pi * 2) * 3;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: UnitSprite(clazz: clazz, size: size, glow: false),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.color,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.button(size: 15)),
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
          border: Border.all(color: Colors.white24, width: 1.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: AppTextStyles.body(size: 12, color: AppColors.text).copyWith(
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(blurRadius: 6, color: Colors.black, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
