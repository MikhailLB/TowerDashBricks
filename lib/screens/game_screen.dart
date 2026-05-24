import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/brick_game.dart';
import '../game/brick_status.dart';
import '../game/level_config.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';

/// Hosts the [BrickGame] inside a [GameWidget] and adds Flutter-side overlays
/// for the HUD (score, timer, combo), pause menu, game-over and level-complete.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelConfig});

  final LevelConfig levelConfig;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  BrickGame? _game;
  late final math.Random _rand = math.Random();
  bool _scoreSubmitted = false;
  int _coinsCreditedFor = 0;
  int _rotationIndex = 0;
  bool _usingGoldRush = false;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _spawnGame();
      });
    });
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  @override
  void dispose() {
    unawaited(setOrientationsLockedPortrait());
    super.dispose();
  }

  void _spawnGame({
    bool craneBrake = false,
    bool hardHat = false,
    bool speedFreeze = false,
    bool steelFoundation = false,
    bool goldRush = false,
  }) {
    _scoreSubmitted = false;
    _coinsCreditedFor = 0;
    _usingGoldRush = goldRush;
    final owned = progress.ownedSkins;
    _rotationIndex = owned.isEmpty ? 0 : _rand.nextInt(owned.length);
    _game = BrickGame(
      skinPicker: _pickSkin,
      levelConfig: widget.levelConfig,
      craneBrakeEnabled: craneBrake,
      hardHatEnabled: hardHat,
      speedFreezeEnabled: speedFreeze,
      steelFoundationEnabled: steelFoundation,
    );
  }

  int _pickSkin() {
    final selected = progress.selectedSkin;
    final owned = progress.ownedSkins;
    if (owned.isEmpty) return 1;
    if (selected != 0 && owned.contains(selected)) return selected;
    final skin = owned[_rotationIndex % owned.length];
    _rotationIndex++;
    return skin;
  }

  Future<void> _onPause() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _game?.setPaused(true);
  }

  void _onResume() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _game?.setPaused(false);
  }

  Future<void> _onUseCraneBrake() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final granted = await progress.consumeSlowHook();
    if (!granted) return;
    setState(() {
      _spawnGame(craneBrake: true);
    });
  }

  Future<void> _onUseBlueprintRetry() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    final granted = await progress.consumeSecondChance();
    if (!granted) return;
    _scoreSubmitted = false;
    _game?.requestBlueprintRetry();
  }

  Future<void> _onRestart() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _spawnGame();
    });
  }

  Future<void> _onExit() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onNextLevel() async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submitFinalScore(int score) async {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    if (score > progress.highScore) {
      await progress.setHighScore(score);
    }
    var delta = score - _coinsCreditedFor;
    if (_usingGoldRush && delta > 0) delta *= 2;
    if (delta > 0) {
      await progress.addCoins(delta);
      _coinsCreditedFor = score;
    }
  }

  Future<void> _onLevelComplete(int score) async {
    if (_scoreSubmitted) return;
    _scoreSubmitted = true;
    await progress.completeLevel(widget.levelConfig.levelNumber);
    if (score > progress.highScore) {
      await progress.setHighScore(score);
    }

    var coins = score;
    if (_usingGoldRush && coins > 0) coins *= 2;
    coins += widget.levelConfig.coinReward;

    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      coins += 20;
    }

    if (coins > 0) await progress.addCoins(coins);
    AudioService.instance.playSfx(Sfx.levelComplete);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (game == null) {
          await _onExit();
          return;
        }
        final status = game.world.status.value;
        if (status == BrickStatus.swinging || status == BrickStatus.falling) {
          game.setPaused(true);
        } else if (status == BrickStatus.paused ||
            status == BrickStatus.gameOver ||
            status == BrickStatus.timedOut ||
            status == BrickStatus.levelComplete) {
          await _onExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: game == null
            ? const _GameLoading()
            : _GameView(
                game: game,
                levelConfig: widget.levelConfig,
                onPause: _onPause,
                onResume: _onResume,
                onRestart: _onRestart,
                onExit: _onExit,
                onNextLevel: _onNextLevel,
                onUseCraneBrake:
                    progress.slowHookBoosts > 0 ? _onUseCraneBrake : null,
                onUseBlueprintRetry: _onUseBlueprintRetry,
                submitFinalScore: _submitFinalScore,
                onLevelComplete: _onLevelComplete,
              ),
      ),
    );
  }
}

class _GameLoading extends StatelessWidget {
  const _GameLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.craneYellow,
            strokeWidth: 4,
          ),
          const SizedBox(height: 18),
          Text('Loading site...', style: AppTextStyles.button(size: 20)),
        ],
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({
    required this.game,
    required this.levelConfig,
    required this.onPause,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    required this.onNextLevel,
    required this.onUseCraneBrake,
    required this.onUseBlueprintRetry,
    required this.submitFinalScore,
    required this.onLevelComplete,
  });

  final BrickGame game;
  final LevelConfig levelConfig;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback onNextLevel;
  final VoidCallback? onUseCraneBrake;
  final Future<void> Function() onUseBlueprintRetry;
  final Future<void> Function(int score) submitFinalScore;
  final Future<void> Function(int score) onLevelComplete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: GameWidget(
            key: ValueKey(game),
            game: game,
            backgroundBuilder: (_) =>
                Container(color: AppColors.background),
            loadingBuilder: (_) => const _GameLoading(),
            errorBuilder: (_, error) => Container(
              color: AppColors.background,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load game:\n$error',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 18),
                ),
              ),
            ),
          ),
        ),

        // HUD — bricks placed, timer, combo
        ValueListenableBuilder<int>(
          valueListenable: game.world.bricksPlaced,
          builder: (context, placed, _) =>
              ValueListenableBuilder<double>(
            valueListenable: game.world.timeRemaining,
            builder: (context, timeLeft, _) =>
                ValueListenableBuilder<int>(
              valueListenable: game.world.combo,
              builder: (context, comboMult, _) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _Hud(
                    bricksPlaced: placed,
                    targetBlocks: levelConfig.targetBlocks,
                    levelNumber: levelConfig.levelNumber,
                    timeLimit: levelConfig.timeLimit,
                    timeRemaining: timeLeft,
                    combo: comboMult,
                    onPause: onPause,
                    craneBrakes: progress.slowHookBoosts,
                    onUseCraneBrake: onUseCraneBrake,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Status overlays
        ValueListenableBuilder<BrickStatus>(
          valueListenable: game.world.status,
          builder: (context, status, _) {
            if (status == BrickStatus.paused) {
              return _PauseOverlay(onResume: onResume, onExit: onExit);
            }
            if (status == BrickStatus.gameOver) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await submitFinalScore(game.world.score.value);
              });
              return _GameOverOverlay(
                score: game.world.score.value,
                highScore:
                    math.max(progress.highScore, game.world.score.value),
                secondChances: progress.secondChanceBoosts,
                timedOut: false,
                onRestart: onRestart,
                onExit: onExit,
                onUseBlueprintRetry:
                    progress.secondChanceBoosts > 0 &&
                            game.world.score.value > 0
                        ? () => onUseBlueprintRetry()
                        : null,
              );
            }
            if (status == BrickStatus.timedOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await submitFinalScore(game.world.score.value);
              });
              return _GameOverOverlay(
                score: game.world.score.value,
                highScore:
                    math.max(progress.highScore, game.world.score.value),
                secondChances: progress.secondChanceBoosts,
                timedOut: true,
                onRestart: onRestart,
                onExit: onExit,
                onUseBlueprintRetry:
                    progress.secondChanceBoosts > 0
                        ? () => onUseBlueprintRetry()
                        : null,
              );
            }
            if (status == BrickStatus.levelComplete) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await onLevelComplete(game.world.score.value);
              });
              return _LevelCompleteOverlay(
                levelConfig: levelConfig,
                score: game.world.score.value,
                onNextLevel: onNextLevel,
                onRestart: onRestart,
                onExit: onExit,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class _Hud extends StatelessWidget {
  const _Hud({
    required this.bricksPlaced,
    required this.targetBlocks,
    required this.levelNumber,
    required this.timeLimit,
    required this.timeRemaining,
    required this.combo,
    required this.onPause,
    required this.craneBrakes,
    required this.onUseCraneBrake,
  });

  final int bricksPlaced;
  final int targetBlocks;
  final int levelNumber;
  final int timeLimit;
  final double timeRemaining;
  final int combo;
  final VoidCallback onPause;
  final int craneBrakes;
  final VoidCallback? onUseCraneBrake;

  @override
  Widget build(BuildContext context) {
    final timerRatio = timeLimit > 0 ? (timeRemaining / timeLimit).clamp(0.0, 1.0) : 1.0;
    final timerColor = timeRemaining <= 10
        ? AppColors.timerDanger
        : timeRemaining <= 20
            ? AppColors.timerWarning
            : AppColors.craneYellow;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundButton(icon: Icons.pause_rounded, onPressed: onPause),
        const Spacer(),

        // Centre info column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.panelSolid.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.craneYellow.withValues(alpha: 0.3)),
              ),
              child: Text('LVL $levelNumber',
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.craneYellow)
                    .copyWith(letterSpacing: 1.5)),
            ),
            const SizedBox(height: 4),

            // Score
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.panelSolid.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '$bricksPlaced / $targetBlocks',
                style: AppTextStyles.score(size: 20),
              ),
            ),
            const SizedBox(height: 4),

            // Timer bar
            Container(
              width: 110,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.panelSolid.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: timerColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_rounded, color: timerColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${timeRemaining.ceil()}s',
                        style: AppTextStyles.button(
                            size: 14, color: timerColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: timerRatio,
                      backgroundColor: Colors.white12,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(timerColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Combo badge (only show if > 1x)
            if (combo > 1) ...[
              const SizedBox(height: 4),
              _ComboBadge(multiplier: combo),
            ],
          ],
        ),

        const Spacer(),

        // Crane brake button
        if (craneBrakes > 0)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RoundButton(
                icon: Icons.speed_rounded,
                onPressed: onUseCraneBrake,
                tint: AppColors.craneYellow.withValues(alpha: 0.85),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    'x$craneBrakes',
                    style:
                        AppTextStyles.body(size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          const SizedBox(width: 48, height: 48),
      ],
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.multiplier});
  final int multiplier;

  @override
  Widget build(BuildContext context) {
    final color =
        multiplier >= 3 ? AppColors.combo3x : AppColors.combo2x;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${multiplier}x COMBO',
        style: AppTextStyles.button(size: 12, color: color),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onPressed, this.tint});
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint ?? AppColors.panelSolid,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.text, size: 26),
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.highScore,
    required this.secondChances,
    required this.timedOut,
    required this.onRestart,
    required this.onExit,
    required this.onUseBlueprintRetry,
  });

  final int score;
  final int highScore;
  final int secondChances;
  final bool timedOut;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback? onUseBlueprintRetry;

  @override
  Widget build(BuildContext context) {
    return _ModalScrim(
      child: _PanelCard(
        title: timedOut ? 'Time Up!' : 'Game Over',
        icon: timedOut ? Icons.timer_off_rounded : Icons.warning_rounded,
        children: [
          Text('Bricks: $score', style: AppTextStyles.score(size: 26)),
          Text(
            'Best: $highScore',
            style: AppTextStyles.body(size: 16, color: AppColors.craneYellow),
          ),
          const SizedBox(height: 16),
          if (onUseBlueprintRetry != null) ...[
            PixelButton(
              label: 'Blueprint Retry (x$secondChances)',
              onPressed: onUseBlueprintRetry,
              fontSize: 16,
              color: PixelButtonColor.primary,
            ),
            const SizedBox(height: 12),
          ],
          PixelButton(label: 'Retry', onPressed: onRestart),
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

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({
    required this.levelConfig,
    required this.score,
    required this.onNextLevel,
    required this.onRestart,
    required this.onExit,
  });

  final LevelConfig levelConfig;
  final int score;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isLastLevel = levelConfig.levelNumber >= levels.length;
    return _ModalScrim(
      child: _PanelCard(
        title: 'Rush Complete!',
        icon: Icons.emoji_events_rounded,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.craneYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.craneYellow, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_rounded,
                    color: AppColors.craneYellow, size: 24),
                const SizedBox(width: 8),
                Text(
                  '+${levelConfig.coinReward} coins',
                  style: AppTextStyles.score(
                      size: 22, color: AppColors.craneYellow),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score bricks stacked',
            style:
                AppTextStyles.body(size: 14, color: Colors.white60),
          ),
          const SizedBox(height: 18),
          if (!isLastLevel) ...[
            PixelButton(
                label: 'Next Level', onPressed: onNextLevel),
            const SizedBox(height: 12),
          ],
          PixelButton(label: 'Play Again', onPressed: onRestart),
          const SizedBox(height: 12),
          PixelButton(
            label: 'Level Select',
            onPressed: onExit,
            color: PixelButtonColor.secondary,
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
      child: child,
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
      margin: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.craneYellow.withValues(alpha: 0.2),
            width: 1.5),
        boxShadow: const [
          BoxShadow(blurRadius: 32, color: Colors.black54),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.craneYellow, size: 36),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.title(size: 32)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
