import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/puzzle_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/blueprint_background.dart';
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

  Future<void> _startLevel(PuzzleLevel level) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(level: level),
      ),
    );
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  @override
  Widget build(BuildContext context) {
    final solved = progress.completedLevels.length;
    final total = puzzleLevels.length;

    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Column(
            children: [
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
                          Text('BLUEPRINT ARCHIVE',
                              style: AppTextStyles.body(
                                size: 11,
                                color: AppColors.craneYellow,
                              ).copyWith(letterSpacing: 3.0)),
                          Text('Choose a Job',
                              style: AppTextStyles.title(size: 26)),
                        ],
                      ),
                    ),
                    _CoinPill(coins: progress.coins),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : solved / total,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.craneYellow),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$solved/$total',
                        style: AppTextStyles.button(
                            size: 13, color: AppColors.craneYellow)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: puzzleLevels.length,
                    itemBuilder: (_, index) {
                      final level = puzzleLevels[index];
                      final unlocked =
                          progress.isLevelUnlocked(level.levelNumber);
                      final completed =
                          progress.isLevelCompleted(level.levelNumber);
                      return _LevelCard(
                        level: level,
                        unlocked: unlocked,
                        completed: completed,
                        onTap: unlocked ? () => _startLevel(level) : null,
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
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final PuzzleLevel level;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = completed
        ? AppColors.craneYellow
        : (unlocked ? AppColors.cardBorder : Colors.white12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2335).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: AppColors.craneYellow.withValues(alpha: 0.18),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'LVL ${level.levelNumber}',
                  style: AppTextStyles.body(
                    size: 10,
                    color: unlocked ? AppColors.craneYellow : Colors.white30,
                  ).copyWith(letterSpacing: 1.5),
                ),
                const Spacer(),
                if (!unlocked)
                  const Icon(Icons.lock_rounded,
                      color: Colors.white30, size: 16)
                else if (completed)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.craneYellow, size: 16)
                else
                  Icon(Icons.play_circle_rounded,
                      color: AppColors.text.withValues(alpha: 0.7), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            // Preview: revealed silhouette once solved, sealed otherwise.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081320),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: completed
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: BlueprintThumbnail(
                          rowsArt: level.rowsArt,
                          size: 78,
                        ),
                      )
                    : Icon(
                        unlocked
                            ? Icons.grid_view_rounded
                            : Icons.lock_outline_rounded,
                        size: 34,
                        color: unlocked
                            ? AppColors.craneYellow.withValues(alpha: 0.5)
                            : Colors.white24,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completed ? level.name : (unlocked ? 'Sealed Blueprint' : 'Locked'),
              style: AppTextStyles.button(
                size: 13,
                color: unlocked ? AppColors.text : Colors.white30,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _MiniStat(
                  icon: Icons.grid_on_rounded,
                  label: '${level.colCount}×${level.rowCount}',
                  color: unlocked ? AppColors.textMuted : Colors.white24,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  icon: Icons.favorite_rounded,
                  label: '${level.lives}',
                  color: unlocked ? AppColors.textMuted : Colors.white24,
                ),
                const Spacer(),
                Icon(Icons.toll_rounded,
                    color: unlocked ? AppColors.craneYellow : Colors.white24,
                    size: 12),
                const SizedBox(width: 2),
                Text(
                  '${level.coinReward}',
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
        Text(label, style: AppTextStyles.body(size: 11, color: color)),
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
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.12), width: 1.5),
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
        color: Colors.black.withValues(alpha: 0.35),
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
