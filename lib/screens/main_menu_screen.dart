import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../main.dart';
import '../services/audio_service.dart';
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
  late final AnimationController _floatCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

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
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full city background ──────────────────────────────────────
          Image.asset(TdbAssets.cityBg, fit: BoxFit.cover),

          // ── Sky-to-transparent gradient overlay (top 55%) ────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xEE0A1520), Color(0x000A1520)],
                ),
              ),
            ),
          ),

          // ── Ground fog overlay (bottom 40%) ──────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF0A1520), Color(0x000A1520)],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // ─ Top bar ─
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.emoji_events_rounded,
                          label: 'Best',
                          value: '${progress.highScore}',
                          color: AppColors.craneYellow,
                        ),
                        const Spacer(),
                        _StatChip(
                          icon: Icons.toll_rounded,
                          label: 'Coins',
                          value: '${progress.coins}',
                          color: AppColors.craneYellow,
                        ),
                        const SizedBox(width: 10),
                        _CircleAction(
                          icon: Icons.settings_rounded,
                          onTap: _openSettings,
                        ),
                      ],
                    ),
                  ),

                  // ─ Logo ─
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        TdbAssets.gameName,
                        width: size.width * 0.80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ─ Floating building ─
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, -8 + 16 * _floatCtrl.value),
                      child: child,
                    ),
                    child: Image.asset(
                      TdbAssets.base,
                      width: size.width * 0.58,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // ─ Bottom action panel ─
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.concrete.withValues(alpha: 0.95),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.25, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary CTA
                        PixelButton(
                          label: 'Rush!',
                          onPressed: _openLevelSelect,
                          width: double.infinity,
                          height: 66,
                          fontSize: 28,
                          icon: Icons.construction_rounded,
                        ),
                        const SizedBox(height: 10),

                        // Shop button
                        PixelButton(
                          label: 'Shop',
                          onPressed: _openShop,
                          width: double.infinity,
                          height: 52,
                          fontSize: 20,
                          color: PixelButtonColor.secondary,
                          icon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 8),

                        // Links — padding inside _LinkBtn keeps tap zone large
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LinkBtn(label: 'Privacy Policy', onTap: _openPrivacy),
                            const Text('·',
                                style: TextStyle(color: Colors.white38)),
                            _LinkBtn(label: 'Support', onTap: _openSupport),
                          ],
                        ),
                        // Safe area bottom padding so links sit above home indicator
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.body(size: 10, color: AppColors.textMuted)
                      .copyWith(letterSpacing: 0.8)),
              Text(value, style: AppTextStyles.button(size: 15, color: AppColors.text)),
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
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
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
        // Extra padding makes the tap area bigger — buttons sit near the
        // bottom home indicator and are hard to hit without it.
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Text(
          label,
          style: AppTextStyles.body(size: 12, color: AppColors.textMuted)
              .copyWith(decoration: TextDecoration.underline,
                  decorationColor: AppColors.textMuted.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
