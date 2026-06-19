import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/arena.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/pixel_button.dart';
import 'battle_screen.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onChange);
  }

  @override
  void dispose() {
    progress.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _findMatch() async {
    if (_searching) return;
    setState(() => _searching = true);
    AudioService.instance.playSfx(Sfx.buttonClick);
    final match = generateArenaMatch(progress.trophies);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final won = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BattleScreen(setup: match.setup)),
    );
    if (!mounted) return;
    if (won == true) {
      await progress.addTrophies(match.trophyGain);
    } else if (won == false) {
      await progress.addTrophies(-match.trophyLoss);
    }
    setState(() => _searching = false);
    AudioService.instance.playBgm(Bgm.menu);
  }

  @override
  Widget build(BuildContext context) {
    final trophies = progress.trophies;
    final league = leagueForTrophies(trophies);
    final next = League.values.firstWhere(
      (l) => l.minTrophies > trophies,
      orElse: () => League.diamond,
    );

    return Scaffold(
      body: BrickBackground(
        skyAsset: TdbAssets.bgNight,
        dim: 0.18,
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LeagueBadge(league: league, trophies: trophies),
                      const SizedBox(height: 24),
                      if (next.minTrophies > trophies)
                        Text(
                          '${next.minTrophies - trophies} trophies to ${next.label}',
                          style: AppTextStyles.body(
                              size: 13, color: AppColors.textMuted),
                        )
                      else
                        Text('Top league reached!',
                            style: AppTextStyles.body(
                                size: 13, color: AppColors.craneYellow)),
                      const SizedBox(height: 30),
                      PixelButton(
                        label: _searching ? 'Matching…' : 'Find Match',
                        icon: Icons.sports_mma_rounded,
                        width: double.infinity,
                        height: 64,
                        onPressed: _searching ? null : _findMatch,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Win to climb the leagues. Your saved deck is your squad — '
                        'arrange your tower at the start of each match.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                            size: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.instance.playSfx(Sfx.buttonClick);
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ARENA',
                  style: AppTextStyles.body(
                          size: 11, color: AppColors.craneYellow)
                      .copyWith(letterSpacing: 3)),
              Text('Ranked Duels', style: AppTextStyles.title(size: 26)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.league, required this.trophies});
  final League league;
  final int trophies;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                league.color.withValues(alpha: 0.9),
                league.color.withValues(alpha: 0.3),
              ],
            ),
            border: Border.all(color: league.color, width: 4),
            boxShadow: [
              BoxShadow(color: league.color.withValues(alpha: 0.5), blurRadius: 26),
            ],
          ),
          child: const Icon(Icons.shield_rounded,
              size: 64, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(league.label.toUpperCase(),
            style: AppTextStyles.headline(size: 30, color: league.color)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.craneYellow, size: 26),
            const SizedBox(width: 8),
            Text('$trophies',
                style: AppTextStyles.score(size: 30, color: AppColors.text)),
          ],
        ),
      ],
    );
  }
}
