import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/campaign.dart';
import '../game/unit_catalog.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/pixel_button.dart';
import '../widgets/unit_card.dart';
import 'battle_screen.dart';

class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
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

  Future<void> _playWave(int globalWave) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final setup = campaignWave(globalWave);
    final won = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BattleScreen(setup: setup)),
    );
    if (won == true) {
      await progress.completeLevel(globalWave);
      // Each cleared wave trains the weakest units a little so progression
      // keeps pace with tougher enemies.
      await progress.grantFreeLevels(2);
      final unlockId = unitUnlockForWave(globalWave);
      if (unlockId != null && !progress.ownsUnit(unlockId)) {
        await progress.grantUnit(unlockId);
        // Auto-add freshly unlocked units to the deck for convenience.
        if (!progress.deck.contains(unlockId)) {
          await progress.setDeck([...progress.deck, unlockId]);
        }
        if (mounted) await _showUnlock(unlockId);
      }
    }
    if (mounted) AudioService.instance.playBgm(Bgm.menu);
  }

  Future<void> _showUnlock(String unitId) {
    final def = unitDefById(unitId);
    if (def == null) return Future.value();
    AudioService.instance.playSfx(Sfx.unlock);
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.panelSolid,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.craneYellow, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.craneYellow.withValues(alpha: 0.4),
                  blurRadius: 26),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('UNIT UNLOCKED!',
                  style: AppTextStyles.headline(
                      size: 22, color: AppColors.craneYellow)),
              const SizedBox(height: 14),
              SizedBox(
                  width: 150, height: 200, child: UnitCard(def: def, level: 1)),
              const SizedBox(height: 10),
              Text('Added to your deck.',
                  style:
                      AppTextStyles.body(size: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              PixelButton(
                label: 'Great!',
                width: 160,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleared = progress.completedLevels.length;
    return Scaffold(
      body: BrickBackground(
        skyAsset: TdbAssets.bgPark,
        dim: 0.15,
        child: SafeArea(
          child: Column(
            children: [
              _Header(cleared: cleared, total: totalWaves),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  children: [
                    for (final chapter in chapters)
                      _ChapterBlock(
                        chapter: chapter,
                        onPlay: _playWave,
                      ),
                  ],
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
  const _Header({required this.cleared, required this.total});
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CAMPAIGN',
                    style: AppTextStyles.body(
                            size: 11, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 3)),
                Text('Build Site', style: AppTextStyles.title(size: 26)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
            ),
            child: Text('$cleared/$total',
                style: AppTextStyles.button(size: 14, color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

class _ChapterBlock extends StatelessWidget {
  const _ChapterBlock({required this.chapter, required this.onPlay});
  final Chapter chapter;
  final void Function(int) onPlay;

  int get _waveOffset {
    var offset = 0;
    for (final c in chapters) {
      if (c.index == chapter.index) break;
      offset += c.waveCount;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelSolid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.craneYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.craneYellow),
                ),
                child: Text('${chapter.index + 1}',
                    style: AppTextStyles.score(
                        size: 18, color: AppColors.craneYellow)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.name, style: AppTextStyles.button(size: 17)),
                    Text(chapter.tagline,
                        style: AppTextStyles.body(
                            size: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var w = 1; w <= chapter.waveCount; w++)
                _WaveDot(
                  globalWave: _waveOffset + w,
                  waveInChapter: w,
                  isBoss: w == chapter.waveCount,
                  onPlay: onPlay,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveDot extends StatelessWidget {
  const _WaveDot({
    required this.globalWave,
    required this.waveInChapter,
    required this.isBoss,
    required this.onPlay,
  });
  final int globalWave;
  final int waveInChapter;
  final bool isBoss;
  final void Function(int) onPlay;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isLevelUnlocked(globalWave);
    final completed = progress.isLevelCompleted(globalWave);
    final size = isBoss ? 58.0 : 48.0;

    Color border;
    Color fill;
    if (completed) {
      border = AppColors.success;
      fill = AppColors.success.withValues(alpha: 0.18);
    } else if (unlocked) {
      border = isBoss ? AppColors.danger : AppColors.craneYellow;
      fill = border.withValues(alpha: 0.16);
    } else {
      border = Colors.white24;
      fill = Colors.black.withValues(alpha: 0.25);
    }

    return GestureDetector(
      onTap: unlocked ? () => onPlay(globalWave) : null,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.8),
        ),
        child: !unlocked
            ? const Icon(Icons.lock_rounded, color: Colors.white30, size: 18)
            : completed
                ? Icon(isBoss ? Icons.emoji_events_rounded : Icons.check_rounded,
                    color: AppColors.success, size: isBoss ? 26 : 20)
                : Icon(
                    isBoss
                        ? Icons.local_fire_department_rounded
                        : Icons.play_arrow_rounded,
                    color: border,
                    size: isBoss ? 28 : 22,
                  ),
      ),
    );
  }
}
