import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/nonogram_controller.dart';
import '../game/puzzle_level.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/blueprint_background.dart';
import '../widgets/blueprint_grid.dart';
import '../widgets/how_to_play.dart';
import '../widgets/pixel_button.dart';

/// Hosts a single Blueprint (nonogram) puzzle. Pure Flutter — the
/// [NonogramController] holds the logic and this screen renders it.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final PuzzleLevel level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late NonogramController _controller;
  final math.Random _rand = math.Random();
  late String _brickAsset;
  bool _rewarded = false;
  bool _usedGoldRush = false;
  bool _dragBlocked = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _brickAsset = TdbAssets.brick(_pickSkin());
    _usedGoldRush = progress.doubleCoinsBoosts > 0;
    _showTutorial = !progress.tutorialSeen;
    _startRound();
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  void _startRound() {
    _rewarded = false;
    _controller = NonogramController(widget.level)..addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  int _pickSkin() {
    final selected = progress.selectedSkin;
    final owned = progress.ownedSkins;
    if (owned.isEmpty) return 1;
    if (selected != 0 && owned.contains(selected)) return selected;
    return owned[_rand.nextInt(owned.length)];
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    unawaited(setOrientationsLockedPortrait());
    super.dispose();
  }

  void _onCellTap(int r, int c) {
    final result = _controller.handleTap(r, c);
    switch (result) {
      case TapResult.placed:
        AudioService.instance.playSfx(Sfx.blockLand);
        break;
      case TapResult.mistake:
        AudioService.instance.playSfx(Sfx.buttonClick);
        AudioService.instance.vibrate(heavy: true);
        break;
      case TapResult.scrappedRound:
        AudioService.instance.playSfx(Sfx.buttonClick);
        AudioService.instance.vibrate(heavy: true);
        break;
      case TapResult.completedRound:
        unawaited(_onComplete());
        break;
      case TapResult.marked:
      case TapResult.removed:
        AudioService.instance.playSfx(Sfx.buttonClick);
        break;
      case TapResult.ignored:
        break;
    }
  }

  void _onDragStart() {
    _dragBlocked = false;
  }

  void _onCellDrag(int r, int c) {
    if (_dragBlocked) return;
    final result = _controller.dragPaint(r, c);
    switch (result) {
      case TapResult.mistake:
      case TapResult.scrappedRound:
        _dragBlocked = true;
        AudioService.instance.playSfx(Sfx.buttonClick);
        AudioService.instance.vibrate(heavy: true);
        break;
      case TapResult.completedRound:
        unawaited(_onComplete());
        break;
      case TapResult.placed:
      case TapResult.marked:
      case TapResult.removed:
      case TapResult.ignored:
        break;
    }
  }

  void _dismissTutorial() {
    setState(() => _showTutorial = false);
    progress.setTutorialSeen();
  }

  Future<void> _onUseHint() async {
    if (!_controller.isInteractive) return;
    final granted = await progress.consumeHint();
    if (!granted) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    final ok = _controller.useHint();
    if (ok && _controller.status == BlueprintStatus.complete) {
      await _onComplete();
    }
  }

  Future<void> _onUseExtraLife() async {
    final granted = await progress.consumeExtraLife();
    if (!granted) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.reviveWithExtraLife();
  }

  Future<void> _onComplete() async {
    if (_rewarded) return;
    _rewarded = true;
    AudioService.instance.playSfx(Sfx.levelComplete);

    await progress.completeLevel(widget.level.levelNumber);
    final solved = progress.completedLevels.length;
    if (solved > progress.highScore) {
      await progress.setHighScore(solved);
    }

    var coins = widget.level.coinReward;
    // Bonus for finishing without spending hints.
    if (_controller.hintsUsed == 0) coins += 20;

    if (_usedGoldRush && progress.doubleCoinsBoosts > 0) {
      await progress.consumeDoubleCoins();
      coins *= 2;
    }
    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      coins += 20;
    }
    if (coins > 0) await progress.addCoins(coins);
  }

  void _onPause() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.pause();
  }

  void _onResume() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.resume();
  }

  void _onRestart() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _controller.removeListener(_onTick);
    _controller.dispose();
    setState(_startRound);
  }

  void _onExit() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (status == BlueprintStatus.building) {
          _controller.pause();
        } else {
          _onExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlueprintBackground(
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      level: widget.level,
                      controller: _controller,
                      hintsAvailable: progress.hintBoosts,
                      onPause: _onPause,
                      onHint: _onUseHint,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: BlueprintGrid(
                          controller: _controller,
                          brickAsset: _brickAsset,
                          onCellTap: _onCellTap,
                          onCellDrag: _onCellDrag,
                          onDragStart: _onDragStart,
                        ),
                      ),
                    ),
                    _ModeBar(
                      mode: _controller.mode,
                      onSelect: _controller.setMode,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (status == BlueprintStatus.paused)
                _PauseOverlay(onResume: _onResume, onExit: _onExit),
              if (status == BlueprintStatus.scrapped)
                _ScrappedOverlay(
                  controller: _controller,
                  extraLives: progress.extraLifeBoosts,
                  onUseExtraLife:
                      progress.extraLifeBoosts > 0 ? _onUseExtraLife : null,
                  onRestart: _onRestart,
                  onExit: _onExit,
                ),
              if (status == BlueprintStatus.complete)
                _CompleteOverlay(
                  level: widget.level,
                  brickAsset: _brickAsset,
                  perfect: _controller.hintsUsed == 0,
                  onNext: _onExit,
                  onRestart: _onRestart,
                  onExit: _onExit,
                ),
              if (_showTutorial)
                HowToPlayOverlay(onClose: _dismissTutorial),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.level,
    required this.controller,
    required this.hintsAvailable,
    required this.onPause,
    required this.onHint,
  });

  final PuzzleLevel level;
  final NonogramController controller;
  final int hintsAvailable;
  final VoidCallback onPause;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Column(
        children: [
          Row(
            children: [
              _RoundButton(icon: Icons.pause_rounded, onTap: onPause),
              const Spacer(),
              Column(
                children: [
                  Text(
                    'BLUEPRINT ${level.levelNumber}',
                    style: AppTextStyles.body(
                            size: 10, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 2.0),
                  ),
                  Text(level.name, style: AppTextStyles.title(size: 22)),
                ],
              ),
              const Spacer(),
              _HintButton(
                count: hintsAvailable,
                onTap: hintsAvailable > 0 ? onHint : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Lives(left: controller.livesLeft, max: controller.maxLives),
              _BrickProgress(
                laid: controller.bricksLaid.clamp(0, controller.bricksTotal),
                total: controller.bricksTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Lives extends StatelessWidget {
  const _Lives({required this.left, required this.max});
  final int left;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelSolid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Icon(
                i < left ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 16,
                color: i < left ? AppColors.danger : Colors.white24,
              ),
            ),
        ],
      ),
    );
  }
}

class _BrickProgress extends StatelessWidget {
  const _BrickProgress({required this.laid, required this.total});
  final int laid;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelSolid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grid_view_rounded,
              color: AppColors.craneYellow, size: 16),
          const SizedBox(width: 6),
          Text('$laid / $total', style: AppTextStyles.button(size: 15)),
        ],
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.craneYellow.withValues(alpha: 0.85)
                  : AppColors.panelSolid,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 1.5),
            ),
            child: Icon(Icons.lightbulb_rounded,
                color: enabled ? AppColors.textDark : Colors.white30, size: 24),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: enabled ? AppColors.danger : Colors.white24,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text('$count',
                  style: AppTextStyles.body(size: 11, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelSolid,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.text, size: 26),
        ),
      ),
    );
  }
}

// ─── Mode bar ────────────────────────────────────────────────────────────────

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.mode, required this.onSelect});
  final EditMode mode;
  final void Function(EditMode) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.panelSolid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            _ModeChip(
              label: 'Lay Brick',
              icon: Icons.add_box_rounded,
              active: mode == EditMode.lay,
              onTap: () => onSelect(EditMode.lay),
            ),
            const SizedBox(width: 5),
            _ModeChip(
              label: 'Mark Gap',
              icon: Icons.close_rounded,
              active: mode == EditMode.mark,
              onTap: () => onSelect(EditMode.mark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.craneYellow.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? AppColors.craneYellow : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: active ? AppColors.craneYellow : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.button(
                  size: 16,
                  color: active ? AppColors.craneYellow : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overlays ────────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onExit});
  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: 'Paused',
        icon: Icons.pause_circle_rounded,
        children: [
          PixelButton(label: 'Continue', onPressed: onResume),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Main Menu',
            onPressed: onExit,
            color: PixelButtonColor.secondary,
          ),
        ],
      ),
    );
  }
}

class _ScrappedOverlay extends StatelessWidget {
  const _ScrappedOverlay({
    required this.controller,
    required this.extraLives,
    required this.onUseExtraLife,
    required this.onRestart,
    required this.onExit,
  });

  final NonogramController controller;
  final int extraLives;
  final VoidCallback? onUseExtraLife;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: 'Blueprint Scrapped',
        icon: Icons.report_problem_rounded,
        children: [
          Text(
            'Too many misplaced bricks!',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (onUseExtraLife != null) ...[
            PixelButton(
              label: 'Reinforce (x$extraLives)',
              onPressed: onUseExtraLife,
              fontSize: 16,
              icon: Icons.shield_rounded,
            ),
            const SizedBox(height: 12),
          ],
          PixelButton(label: 'Restart', onPressed: onRestart),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Main Menu',
            onPressed: onExit,
            color: PixelButtonColor.secondary,
          ),
        ],
      ),
    );
  }
}

class _CompleteOverlay extends StatelessWidget {
  const _CompleteOverlay({
    required this.level,
    required this.brickAsset,
    required this.perfect,
    required this.onNext,
    required this.onRestart,
    required this.onExit,
  });

  final PuzzleLevel level;
  final String brickAsset;
  final bool perfect;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isLast = level.levelNumber >= puzzleLevels.length;
    return _ModalScrim(
      child: _PanelCard(
        title: 'Blueprint Built!',
        icon: Icons.verified_rounded,
        children: [
          _BuiltPreview(level: level, brickAsset: brickAsset),
          const SizedBox(height: 12),
          Text(level.name, style: AppTextStyles.button(size: 18)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.craneYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.craneYellow, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_rounded,
                    color: AppColors.craneYellow, size: 22),
                const SizedBox(width: 8),
                Text(
                  '+${level.coinReward}${perfect ? ' +20' : ''} coins',
                  style: AppTextStyles.score(
                      size: 20, color: AppColors.craneYellow),
                ),
              ],
            ),
          ),
          if (perfect) ...[
            const SizedBox(height: 6),
            Text('Perfect — no hints used!',
                style:
                    AppTextStyles.body(size: 12, color: AppColors.success)),
          ],
          const SizedBox(height: 18),
          if (!isLast) ...[
            PixelButton(label: 'Continue', onPressed: onNext),
            const SizedBox(height: 12),
          ],
          PixelButton(
            label: 'Replay',
            onPressed: onRestart,
            color: PixelButtonColor.secondary,
          ),
        ],
      ),
    );
  }
}

/// Small render of the finished blueprint using the player's brick skin.
class _BuiltPreview extends StatelessWidget {
  const _BuiltPreview({required this.level, required this.brickAsset});
  final PuzzleLevel level;
  final String brickAsset;

  @override
  Widget build(BuildContext context) {
    const maxSize = 150.0;
    final cell = maxSize / math.max(level.rowCount, level.colCount);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.craneYellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < level.rowCount; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < level.colCount; c++)
                  SizedBox(
                    width: cell,
                    height: cell,
                    child: level.solutionAt(r, c)
                        ? Image.asset(brickAsset,
                            fit: BoxFit.fill, gaplessPlayback: true)
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModalScrim extends StatelessWidget {
  const _ModalScrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.center,
      child: SingleChildScrollView(child: child),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.2), width: 1.5),
        boxShadow: const [
          BoxShadow(blurRadius: 32, color: Colors.black54),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.craneYellow, size: 36),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.title(size: 28)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
