import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../game/battle_controller.dart';
import '../game/battle_setup.dart';
import '../game/brick_unit.dart';
import '../game/synergies.dart';
import '../game/tower.dart';
import '../game/unit_catalog.dart';
import '../game/unit_class.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/brick_background.dart';
import '../widgets/pixel_button.dart';
import '../widgets/battle_fx.dart';
import '../widgets/tower_view.dart';
import '../widgets/unit_card.dart';
import '../widgets/unit_sprite.dart';

enum _Stage { building, fighting }

class _Placeable {
  _Placeable(this.def, this.level);
  final UnitDef def;
  final int level;
}

/// Hosts one battle: a build phase (arrange your tower from your deck) and the
/// auto-battle itself with code-drawn VFX.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.setup});

  final BattleSetup setup;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  static const _stepDelay = Duration(milliseconds: 720);

  _Stage _stage = _Stage.building;
  BattleController? _ctrl;
  Timer? _timer;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _craneBob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  late final AnimationController _hookDrop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  final List<_Placeable> _hand = [];
  final List<_Placeable> _placed = [];
  int? _justPlacedIndex;

  // Fight-phase transient FX state.
  final GlobalKey _fieldKey = GlobalKey();
  List<GlobalKey> _playerKeys = [];
  List<GlobalKey> _enemyKeys = [];
  int? _activePlayer;
  int? _activeEnemy;
  Set<int> _playerHits = {};
  Set<int> _enemyHits = {};
  final List<Widget> _fx = [];
  int _fxSeq = 0;

  bool _rewarded = false;
  bool _usedGoldRush = false;
  int _earnedCoins = 0;

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _usedGoldRush = progress.doubleCoinsBoosts > 0;
    // Build the bench from the saved deck, or fall back to every owned unit so
    // the player always has a roster to pick from. Nobody is deployed by
    // default — the player chooses who climbs the tower.
    final sourceIds =
        progress.deck.isNotEmpty ? progress.deck : progress.ownedUnits.keys;
    for (final id in sourceIds) {
      final def = unitDefById(id);
      final level = progress.ownedUnits[id];
      if (def != null && level != null) _hand.add(_Placeable(def, level));
    }
    AudioService.instance.playBgm(Bgm.gameplay);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl?.dispose();
    _shake.dispose();
    _craneBob.dispose();
    _hookDrop.dispose();
    super.dispose();
  }

  // ── Build phase actions ──────────────────────────────────────────────

  void _place(_Placeable p) {
    if (_placed.length >= widget.setup.deckSlots) return;
    AudioService.instance.playSfx(Sfx.deploy);
    AudioService.instance.vibrate();
    setState(() {
      _hand.remove(p);
      _placed.add(p);
      _justPlacedIndex = _placed.length - 1;
    });
    _hookDrop.forward(from: 0);
  }

  void _unplace(_Placeable p) {
    AudioService.instance.playSfx(Sfx.buttonClick);
    setState(() {
      _placed.remove(p);
      _hand.add(p);
      _justPlacedIndex = null;
    });
  }

  List<SynergyBonus> get _previewSynergies {
    final units = [for (final p in _placed) BrickUnit(def: p.def, level: p.level)];
    return SynergyEngine.compute(units);
  }

  void _startBattle() {
    if (_placed.isEmpty) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    final playerUnits = [
      for (final p in _placed) BrickUnit(def: p.def, level: p.level)
    ];
    final enemyUnits = widget.setup.buildEnemyUnits();
    final ctrl = BattleController(
      playerUnits: playerUnits,
      enemyUnits: enemyUnits,
    );
    _playerKeys = List.generate(playerUnits.length, (_) => GlobalKey());
    _enemyKeys = List.generate(enemyUnits.length, (_) => GlobalKey());
    ctrl.begin();
    setState(() {
      _ctrl = ctrl;
      _stage = _Stage.fighting;
    });
    _scheduleStep();
  }

  // ── Fight phase loop ─────────────────────────────────────────────────

  void _scheduleStep() {
    _timer = Timer(_stepDelay, () {
      final ctrl = _ctrl;
      if (ctrl == null || !mounted) return;
      final event = ctrl.step();
      if (event != null) _applyEventFx(event);
      if (ctrl.isFighting) {
        _scheduleStep();
      } else {
        _onBattleEnd();
      }
    });
  }

  void _applyEventFx(BattleEvent event) {
    setState(() {
      _activePlayer = event.attacker.isPlayer ? event.attacker.index : null;
      _activeEnemy = event.attacker.isPlayer ? null : event.attacker.index;
      _playerHits = {};
      _enemyHits = {};
      for (final t in event.targets) {
        if (event.type == BattleActionType.heal) continue;
        if (t.isPlayer) {
          _playerHits.add(t.index);
        } else {
          _enemyHits.add(t.index);
        }
      }
    });

    if (event.type == BattleActionType.attack ||
        event.type == BattleActionType.splash) {
      AudioService.instance.playHit();
    }
    if (event.deaths.isNotEmpty) {
      AudioService.instance.vibrate(heavy: true);
      _shake.forward(from: 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _spawnEventVisuals(event);
    });
  }

  Offset? _centerOf(GlobalKey key) {
    final field = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (field == null || box == null) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return field.globalToLocal(global);
  }

  void _spawnEventVisuals(BattleEvent event) {
    final attackerKeys = event.attacker.isPlayer ? _playerKeys : _enemyKeys;
    final attackerCenter = (event.attacker.index < attackerKeys.length)
        ? _centerOf(attackerKeys[event.attacker.index])
        : null;

    final ranged = event.attackerClass == UnitClass.archer ||
        event.attackerClass == UnitClass.mage ||
        event.attackerClass == UnitClass.bomber;

    for (final t in event.targets) {
      final keys = t.isPlayer ? _playerKeys : _enemyKeys;
      if (t.index >= keys.length) continue;
      final center = _centerOf(keys[t.index]);
      if (center == null) continue;

      final isHeal = event.type == BattleActionType.heal;
      final text = isHeal ? '+${event.amount}' : '-${event.amount}';
      final color = isHeal ? AppColors.success : Colors.white;

      void addNumber() => _addFx((key, done) => FloatingNumber(
            key: key,
            center: center,
            text: text,
            color: color,
            big: event.attackerClass == UnitClass.bomber || isHeal,
            onDone: done,
          ));

      if (!isHeal) {
        _addFx((key, done) => ImpactRing(
              key: key,
              center: center,
              color: event.attackerClass.color,
              onDone: done,
            ));
      }

      if (ranged && attackerCenter != null && !isHeal) {
        _addFx((key, done) => Projectile(
              key: key,
              start: attackerCenter,
              end: center,
              attackerClass: event.attackerClass,
              onDone: () {
                done();
                if (mounted) addNumber();
              },
            ));
      } else {
        addNumber();
      }
    }

    // Brick-shatter burst for each destroyed unit.
    final ctrl = _ctrl;
    if (ctrl != null) {
      for (final d in event.deaths) {
        final keys = d.isPlayer ? _playerKeys : _enemyKeys;
        if (d.index >= keys.length) continue;
        final center = _centerOf(keys[d.index]);
        if (center == null) continue;
        final tower = d.isPlayer ? ctrl.player : ctrl.enemy;
        final color = tower.units[d.index].clazz.color;
        _addFx((key, done) => ShatterBurst(
              key: key,
              center: center,
              color: color,
              onDone: done,
            ));
      }
    }
  }

  void _addFx(Widget Function(Key key, VoidCallback onDone) build) {
    final key = ValueKey('fx_${_fxSeq++}');
    late Widget widget;
    void remove() {
      if (!mounted) return;
      setState(() => _fx.remove(widget));
    }

    widget = build(key, remove);
    setState(() => _fx.add(widget));
  }

  // ── Results ──────────────────────────────────────────────────────────

  Future<void> _onBattleEnd() async {
    final ctrl = _ctrl!;
    if (ctrl.phase == BattlePhase.won) {
      AudioService.instance.playSfx(Sfx.victory);
      await _grantRewards();
    } else {
      AudioService.instance.playSfx(Sfx.defeat);
      AudioService.instance.vibrate(heavy: true);
      await _grantConsolation();
    }
    if (mounted) setState(() {});
  }

  Future<void> _grantRewards() async {
    if (_rewarded) return;
    _rewarded = true;

    var coins = widget.setup.coinReward;
    if (_usedGoldRush && progress.doubleCoinsBoosts > 0) {
      await progress.consumeDoubleCoins();
      coins *= 2;
    }
    if (progress.luckyBoosts > 0) {
      await progress.consumeLucky();
      coins += 20;
    }
    _earnedCoins = coins;
    if (coins > 0) await progress.addCoins(coins);
    if (widget.setup.gemReward > 0) {
      await progress.addGems(widget.setup.gemReward);
    }
  }

  /// Even a loss pays out a small purse so the player can always keep grinding
  /// coins toward upgrades and never gets fully stuck.
  Future<void> _grantConsolation() async {
    if (_rewarded) return;
    _rewarded = true;
    final coins = (widget.setup.coinReward * 0.3).round().clamp(12, 90);
    _earnedCoins = coins;
    await progress.addCoins(coins);
  }

  Future<void> _reinforce() async {
    final granted = await progress.consumeExtraLife();
    if (!granted) return;
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (_ctrl!.reinforce()) {
      setState(() {});
      _scheduleStep();
    }
  }

  void _retry() {
    AudioService.instance.playSfx(Sfx.buttonClick);
    _timer?.cancel();
    _ctrl?.dispose();
    setState(() {
      _ctrl = null;
      _stage = _Stage.building;
      _rewarded = false;
      _earnedCoins = 0;
      _fx.clear();
      _activePlayer = null;
      _activeEnemy = null;
      _playerHits = {};
      _enemyHits = {};
      // Return everything to the bench for re-arranging.
      _hand.addAll(_placed);
      _placed.clear();
    });
  }

  void _exit(bool won) {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (mounted) Navigator.of(context).pop(won);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phase = _ctrl?.phase;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exit(phase == BattlePhase.won);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BrickBackground(
          skyAsset: widget.setup.backgroundAsset,
          showGround: true,
          dim: 0.05,
          child: SafeArea(
            child: Stack(
              children: [
                if (_stage == _Stage.building)
                  _buildPhase()
                else
                  _fightPhase(),
                if (phase == BattlePhase.won)
                  _ResultOverlay(
                    won: true,
                    setup: widget.setup,
                    earnedCoins: _earnedCoins,
                    onPrimary: () => _exit(true),
                  ),
                if (phase == BattlePhase.lost)
                  _ResultOverlay(
                    won: false,
                    setup: widget.setup,
                    earnedCoins: _earnedCoins,
                    canReinforce:
                        _ctrl!.canReinforce && progress.extraLifeBoosts > 0,
                    reinforceCount: progress.extraLifeBoosts,
                    onReinforce: _reinforce,
                    onRetry: _retry,
                    onPrimary: () => _exit(false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build phase UI ───────────────────────────────────────────────────

  Widget _buildPhase() {
    final synergies = _previewSynergies;
    final slots = widget.setup.deckSlots;
    return Column(
      children: [
        _TopBar(
          title: widget.setup.title,
          subtitle: widget.setup.subtitle,
          onExit: () => _exit(false),
        ),
        _EnemyPreview(setup: widget.setup),
        Expanded(
          flex: 6,
          child: _ConstructionSite(
            placed: _placed,
            slots: slots,
            craneBob: _craneBob,
            hookDrop: _hookDrop,
            justPlacedIndex: _justPlacedIndex,
            onRemove: _unplace,
          ),
        ),
        if (synergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _SynergyChips(synergies: synergies),
          ),
        Expanded(
          flex: 5,
          child: _SquadRoster(
            hand: _hand,
            full: _placed.length >= slots,
            onPlace: _place,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: PixelButton(
            label: _placed.isEmpty ? 'Pick your squad' : 'Start Battle',
            icon: Icons.local_fire_department_rounded,
            width: double.infinity,
            height: 58,
            onPressed: _placed.isEmpty ? null : _startBattle,
          ),
        ),
      ],
    );
  }

  // ── Fight phase UI ───────────────────────────────────────────────────

  Widget _fightPhase() {
    final ctrl = _ctrl!;
    return Stack(
      key: _fieldKey,
      children: [
        Column(
          children: [
            _TopBar(
              title: widget.setup.title,
              subtitle: 'Round ${ctrl.round}',
              onExit: () => _exit(ctrl.phase == BattlePhase.won),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _TowerHpBar(
                      tower: ctrl.player,
                      label: 'YOUR TOWER',
                      color: AppColors.success,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _VsBadge(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TowerHpBar(
                      tower: ctrl.enemy,
                      label: widget.setup.isBoss ? 'BOSS' : 'ENEMY',
                      color: AppColors.danger,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final maxUnits = [
                      ctrl.player.units.length,
                      ctrl.enemy.units.length,
                      1,
                    ].reduce((a, b) => a > b ? a : b);
                    final byWidth = c.maxWidth / 2 - 36;
                    final byHeight = c.maxHeight / maxUnits - 24;
                    final tile = (byWidth < byHeight ? byWidth : byHeight)
                        .clamp(30.0, 74.0);
                    return AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) {
                        final t = _shake.value;
                        final amp = 6 * (1 - t);
                        final dx = math.sin(t * math.pi * 8) * amp;
                        return Transform.translate(
                            offset: Offset(dx, 0), child: child);
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _GroundedTower(
                              tower: ctrl.player,
                              isEnemy: false,
                              tileKeys: _playerKeys,
                              tile: tile,
                              activeIndex: _activePlayer,
                              hitIndices: _playerHits,
                            ),
                          ),
                          Expanded(
                            child: _GroundedTower(
                              tower: ctrl.enemy,
                              isEnemy: true,
                              tileKeys: _enemyKeys,
                              tile: tile,
                              activeIndex: _activeEnemy,
                              hitIndices: _enemyHits,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // The crane that built your tower watches over the player's side, its
        // hook still swaying above the battlements.
        Positioned(
          top: 58,
          left: -10,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _craneBob,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _craneBob.value * 7 - 3.5),
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(TdbAssets.crane, width: 118),
                  Container(width: 2, height: 10, color: const Color(0xFF3A4660)),
                  Image.asset(TdbAssets.craneHook, width: 22),
                ],
              ),
            ),
          ),
        ),
        ..._fx,
      ],
    );
  }
}

/// A tower resting on a stone base plate, anchored to the bottom (ground).
class _GroundedTower extends StatelessWidget {
  const _GroundedTower({
    required this.tower,
    required this.isEnemy,
    required this.tileKeys,
    required this.tile,
    required this.activeIndex,
    required this.hitIndices,
  });

  final Tower tower;
  final bool isEnemy;
  final List<GlobalKey> tileKeys;
  final double tile;
  final int? activeIndex;
  final Set<int> hitIndices;

  @override
  Widget build(BuildContext context) {
    final sideColor = isEnemy ? AppColors.danger : AppColors.success;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: SingleChildScrollView(
            reverse: true,
            physics: const NeverScrollableScrollPhysics(),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tile * 0.06),
                    child: BrickTowerBackdrop(sideColor: sideColor),
                  ),
                ),
                TowerView(
                  tower: tower,
                  isEnemy: isEnemy,
                  tileKeys: tileKeys,
                  tileSize: tile,
                  activeIndex: activeIndex,
                  hitIndices: hitIndices,
                ),
              ],
            ),
          ),
        ),
        // Ground shadow + base plate for a planted look.
        Container(
          width: tile * 1.7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -3),
          child: Image.asset(
            TdbAssets.base,
            width: tile * 1.95,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }
}

class _TowerHpBar extends StatelessWidget {
  const _TowerHpBar({
    required this.tower,
    required this.label,
    required this.color,
    required this.alignEnd,
  });
  final Tower tower;
  final String label;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    var hp = 0;
    var maxHp = 0;
    for (final u in tower.units) {
      hp += u.hp;
      maxHp += u.maxHp;
    }
    final frac = maxHp == 0 ? 0.0 : hp / maxHp;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Icon(Icons.favorite_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.body(size: 10, color: color)
                    .copyWith(letterSpacing: 1.2)),
            const SizedBox(width: 6),
            Text('${tower.aliveCount}/${tower.units.length}',
                style: AppTextStyles.body(size: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            color: Colors.black.withValues(alpha: 0.5),
            child: Align(
              alignment:
                  alignEnd ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: frac.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VsBadge extends StatelessWidget {
  const _VsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.panelSolid,
        border: Border.all(color: AppColors.craneYellow, width: 2),
        boxShadow: [
          BoxShadow(
              color: AppColors.craneYellow.withValues(alpha: 0.4),
              blurRadius: 10),
        ],
      ),
      child: Text('VS',
          style: AppTextStyles.button(size: 12, color: AppColors.craneYellow)),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onExit,
  });
  final String title;
  final String subtitle;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onExit,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.text),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: AppTextStyles.title(size: 22)),
                Text(subtitle,
                    style: AppTextStyles.body(
                            size: 11, color: AppColors.craneYellow)
                        .copyWith(letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _EnemyPreview extends StatelessWidget {
  const _EnemyPreview({required this.setup});
  final BattleSetup setup;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger, width: 1.5),
            ),
            alignment: Alignment.center,
            child: setup.isBoss && setup.bossAsset != null
                ? Image.asset(setup.bossAsset!, width: 58, height: 58)
                : const Icon(Icons.dangerous_rounded,
                    color: AppColors.danger, size: 32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(setup.isBoss ? 'BOSS' : 'ENEMY',
                        style: AppTextStyles.button(
                            size: 13, color: AppColors.danger)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('PWR ${setup.enemyPower}',
                          style: AppTextStyles.body(
                              size: 10, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (setup.isSoloBoss)
                  Row(
                    children: [
                      Icon(setup.boss!.ability.icon,
                          size: 14, color: AppColors.craneYellow),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${setup.boss!.ability.label} · '
                          '${setup.boss!.ability.description}',
                          style: AppTextStyles.body(
                              size: 11, color: AppColors.text),
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final e in setup.enemies)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.5)),
                          ),
                          child: UnitSprite(
                            clazz: e.clazz,
                            rarity: e.rarity,
                            size: 28,
                            glow: false,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The construction-site panel for the build phase: a crane with a dangling
/// hook lifts your chosen units onto a tower that rises from a shop base.
/// This is the "selected units" UI — tap a floor to send that unit back.
class _ConstructionSite extends StatelessWidget {
  const _ConstructionSite({
    required this.placed,
    required this.slots,
    required this.craneBob,
    required this.hookDrop,
    required this.justPlacedIndex,
    required this.onRemove,
  });

  final List<_Placeable> placed;
  final int slots;
  final Animation<double> craneBob;
  final Animation<double> hookDrop;
  final int? justPlacedIndex;
  final void Function(_Placeable) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.34),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.craneYellow.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.construction_rounded,
                  size: 15, color: AppColors.craneYellow),
              const SizedBox(width: 6),
              Text('YOUR TOWER',
                  style:
                      AppTextStyles.body(size: 11, color: AppColors.craneYellow)
                          .copyWith(letterSpacing: 2)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${placed.length}/$slots floors',
                    style: AppTextStyles.button(
                        size: 12, color: AppColors.text)),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // Reserve headroom for the crane, then size floors so a full
                // tower (every slot + the base) still fits without overflow.
                final usable = c.maxHeight - 84;
                final tile =
                    (usable / (slots + 1.2)).clamp(26.0, 54.0).toDouble();
                return Stack(
                  children: [
                    // The tower, growing from the base at the bottom.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(child: _tower(tile)),
                    ),
                    // The crane parked at the top with a swaying hook.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: _craneRig()),
                    ),
                    if (placed.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 64,
                        child: Text(
                          'Tap a unit below — the crane lifts it onto your tower',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                              size: 12, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _craneRig() {
    return AnimatedBuilder(
      animation: craneBob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, craneBob.value * 5 - 2.5),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: hookDrop,
        builder: (context, _) {
          final drop = math.sin(hookDrop.value * math.pi) * 16;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(TdbAssets.crane, width: 108, gaplessPlayback: true),
              Container(
                width: 2.5,
                height: 8 + drop,
                color: const Color(0xFF3A4660),
              ),
              Image.asset(TdbAssets.craneHook,
                  width: 26, gaplessPlayback: true),
            ],
          );
        },
      ),
    );
  }

  Widget _tower(double tile) {
    // Show a single "next floor" hint when there's still room, so the tower
    // height stays bounded by the number of deployed units.
    final ghosts = placed.length < slots ? 1 : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Empty capacity shown as a faint ghost floor under the hook.
        for (var g = 0; g < ghosts; g++) _ghostFloor(tile),
        // Placed units, top of tower first (slot 1 sits on the base).
        for (var i = placed.length - 1; i >= 0; i--)
          _floorTile(i, tile),
        // Shop base plate from the original Tower Dash Bricks.
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Image.asset(
            TdbAssets.shopBase,
            width: tile * 1.7,
            fit: BoxFit.fitWidth,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }

  Widget _ghostFloor(double tile) {
    return Container(
      width: tile * 1.5,
      height: tile * 0.6,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.craneYellow.withValues(alpha: 0.32),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(Icons.add_rounded,
            size: tile * 0.32,
            color: AppColors.craneYellow.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _floorTile(int i, double tile) {
    final p = placed[i];
    final color = p.def.clazz.color;
    // A compact brick floor: just the unit portrait framed in its class color,
    // with a small level chip and a remove hint. Keeps the tower narrow and
    // overflow-free no matter how many floors are stacked.
    final tile0 = Container(
      width: tile * 1.5,
      height: tile * 0.96,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.panelLight.withValues(alpha: 0.95),
            AppColors.card.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 7),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          UnitSprite(
              clazz: p.def.clazz,
              rarity: p.def.rarity,
              size: tile * 0.82,
              glow: false),
          // Level chip, bottom-left.
          Positioned(
            left: 3,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Lv${p.level}',
                  style: AppTextStyles.body(size: 8, color: AppColors.text)),
            ),
          ),
          // Remove hint, top-right.
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child:
                  const Icon(Icons.close_rounded, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // The freshly placed floor drops in from the hook.
    Widget animated = tile0;
    if (i == justPlacedIndex) {
      animated = AnimatedBuilder(
        animation: hookDrop,
        builder: (context, child) {
          final t = Curves.easeOutBack.transform(hookDrop.value);
          return Transform.translate(
            offset: Offset(0, (1 - t) * -tile * 1.2),
            child: Opacity(opacity: hookDrop.value.clamp(0.0, 1.0), child: child),
          );
        },
        child: tile0,
      );
    }

    return GestureDetector(onTap: () => onRemove(p), child: animated);
  }
}

/// The squad roster the player picks from in the build phase. Nobody is
/// deployed automatically; tapping a card sends that unit up the crane.
class _SquadRoster extends StatelessWidget {
  const _SquadRoster({
    required this.hand,
    required this.full,
    required this.onPlace,
  });

  final List<_Placeable> hand;
  final bool full;
  final void Function(_Placeable) onPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded,
                  size: 15, color: AppColors.craneYellow),
              const SizedBox(width: 6),
              Text('CHOOSE YOUR SQUAD',
                  style:
                      AppTextStyles.body(size: 11, color: AppColors.craneYellow)
                          .copyWith(letterSpacing: 2)),
              const Spacer(),
              if (full)
                Text('Tower full',
                    style: AppTextStyles.body(
                        size: 10, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hand.isEmpty
                ? Center(
                    child: Text(
                      full
                          ? 'Every unit is on the tower.'
                          : 'No units available.',
                      style: AppTextStyles.body(
                          size: 13, color: AppColors.textMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    itemCount: hand.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) => UnitCard(
                      def: hand[i].def,
                      level: hand[i].level,
                      dimmed: full,
                      onTap: full ? null : () => onPlace(hand[i]),
                      badge: full
                          ? null
                          : Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.craneYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 11, color: AppColors.textDark),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SynergyChips extends StatelessWidget {
  const _SynergyChips({required this.synergies});
  final List<SynergyBonus> synergies;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in synergies)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: s.clazz.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.clazz.color, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.clazz.icon, size: 13, color: s.clazz.color),
                const SizedBox(width: 5),
                Text(s.description,
                    style: AppTextStyles.body(size: 11, color: AppColors.text)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.won,
    required this.setup,
    required this.earnedCoins,
    required this.onPrimary,
    this.canReinforce = false,
    this.reinforceCount = 0,
    this.onReinforce,
    this.onRetry,
  });

  final bool won;
  final BattleSetup setup;
  final int earnedCoins;
  final VoidCallback onPrimary;
  final bool canReinforce;
  final int reinforceCount;
  final VoidCallback? onReinforce;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
          decoration: BoxDecoration(
            color: AppColors.panelSolid,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: won ? AppColors.success : AppColors.danger,
              width: 1.5,
            ),
            boxShadow: const [BoxShadow(blurRadius: 32, color: Colors.black54)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                won ? Icons.emoji_events_rounded : Icons.heart_broken_rounded,
                color: won ? AppColors.craneYellow : AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(won ? 'Victory!' : 'Defeated',
                  style: AppTextStyles.title(size: 30)),
              const SizedBox(height: 14),
              if (won) ...[
                _RewardRow(
                  icon: Icons.toll_rounded,
                  color: AppColors.neonGold,
                  text: '+$earnedCoins coins',
                ),
                if (setup.gemReward > 0) ...[
                  const SizedBox(height: 6),
                  _RewardRow(
                    icon: Icons.diamond_rounded,
                    color: AppColors.archer,
                    text: '+${setup.gemReward} gems',
                  ),
                ],
              ] else ...[
                Text('Your tower fell — but you still earned some coins.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                        size: 13, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                _RewardRow(
                  icon: Icons.toll_rounded,
                  color: AppColors.neonGold,
                  text: '+$earnedCoins coins',
                ),
              ],
              const SizedBox(height: 18),
              if (!won && canReinforce && onReinforce != null) ...[
                PixelButton(
                  label: 'Reinforce (x$reinforceCount)',
                  icon: Icons.shield_rounded,
                  width: double.infinity,
                  onPressed: onReinforce,
                ),
                const SizedBox(height: 10),
              ],
              if (!won && onRetry != null) ...[
                PixelButton(
                  label: 'Rebuild Tower',
                  width: double.infinity,
                  color: PixelButtonColor.secondary,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 10),
              ],
              PixelButton(
                label: won ? 'Continue' : 'Leave',
                width: double.infinity,
                color: won
                    ? PixelButtonColor.primary
                    : PixelButtonColor.secondary,
                onPressed: onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.score(size: 18, color: color)),
      ],
    );
  }
}
