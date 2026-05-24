import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/level_config.dart';
import '../main.dart';
import '../services/audio_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startLevel(LevelConfig config) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(levelConfig: config),
      ),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1520), Color(0xFF1A2D42), Color(0xFF0D1B2A)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () {
                      AudioService.instance.playSfx(Sfx.buttonClick);
                      Navigator.of(context).pop();
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SELECT LEVEL',
                              style: AppTextStyles.body(
                                size: 11,
                                color: AppColors.craneYellow,
                              ).copyWith(letterSpacing: 3.0)),
                          Text('Brick Tower Rush',
                              style: AppTextStyles.title(size: 26)),
                        ],
                      ),
                    ),
                    _CoinPill(coins: progress.coins),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.craneYellow.withValues(alpha: 0.2),
              ),

              const SizedBox(height: 12),

              // Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (_, index) {
                      final config = levels[index];
                      final unlocked =
                          progress.isLevelUnlocked(config.levelNumber);
                      final completed =
                          progress.isLevelCompleted(config.levelNumber);
                      return _LevelCard(
                        config: config,
                        unlocked: unlocked,
                        completed: completed,
                        onTap: unlocked ? () => _startLevel(config) : null,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.config,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final LevelConfig config;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasWind = config.windStrength > 0;

    final borderColor = completed
        ? AppColors.craneYellow
        : (unlocked
            ? AppColors.cardBorder
            : Colors.white12);
    final bgTop = completed
        ? AppColors.brickRed.withValues(alpha: 0.3)
        : (unlocked ? AppColors.panelSolid : AppColors.panelSolid.withValues(alpha: 0.4));
    final bgBottom = completed
        ? AppColors.concrete
        : AppColors.card;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: AppColors.craneYellow.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level number + status
            Row(
              children: [
                Text(
                  'LVL ${config.levelNumber}',
                  style: AppTextStyles.body(
                    size: 10,
                    color: unlocked
                        ? AppColors.craneYellow
                        : Colors.white30,
                  ).copyWith(letterSpacing: 1.5),
                ),
                const Spacer(),
                if (!unlocked)
                  const Icon(Icons.lock_rounded,
                      color: Colors.white30, size: 16)
                else if (completed)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.craneYellow, size: 16)
                else
                  Icon(Icons.play_circle_rounded,
                      color: AppColors.text.withValues(alpha: 0.7),
                      size: 16),
              ],
            ),

            // Level name
            Text(
              config.levelName,
              style: AppTextStyles.button(
                size: 15,
                color: unlocked ? AppColors.text : Colors.white30,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Stats row
            Row(
              children: [
                _MiniStat(
                  icon: Icons.layers_rounded,
                  label: '${config.targetBlocks}',
                  color: unlocked ? AppColors.text : Colors.white24,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  icon: Icons.timer_rounded,
                  label: '${config.timeLimit}s',
                  color: unlocked ? AppColors.text : Colors.white24,
                ),
                if (hasWind) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.air_rounded,
                      color: unlocked
                          ? AppColors.craneYellow.withValues(alpha: 0.8)
                          : Colors.white24,
                      size: 14),
                ],
                const Spacer(),
                Icon(Icons.toll_rounded,
                    color: unlocked ? AppColors.craneYellow : Colors.white24,
                    size: 12),
                const SizedBox(width: 2),
                Text(
                  '${config.coinReward}',
                  style: AppTextStyles.body(
                    size: 11,
                    color: unlocked ? AppColors.craneYellow : Colors.white24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 2),
        Text(label,
            style: AppTextStyles.body(size: 11, color: color)),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.panelSolid,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: AppColors.text, size: 24),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded,
              color: AppColors.craneYellow, size: 20),
          const SizedBox(width: 6),
          Text('$coins', style: AppTextStyles.button(size: 16)),
        ],
      ),
    );
  }
}
