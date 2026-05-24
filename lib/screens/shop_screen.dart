import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../app/tdb_assets.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';

/// Forge Yard shop — tab-based layout with Brick Skins and Power-Ups sections.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  static const Map<int, int> _skinPrices = {1: 10, 2: 100, 3: 500};
  static const int _firstComingSoonSkin = 4;

  static const _craneBrakePrice = 35;
  static const _blueprintRetryPrice = 60;
  static const _goldRushPrice = 80;
  static const _hardHatPrice = 45;
  static const _concreteLockPrice = 70;
  static const _steelFoundationPrice = 55;
  static const _foremanLuckPrice = 30;

  late final TabController _tabs;

  bool _isComingSoon(int skin) => skin >= _firstComingSoonSkin;
  int? _priceOf(int skin) => _skinPrices[skin];

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _tabs = TabController(length: 2, vsync: this);
    progress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    progress.removeListener(_onProgressChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _buySkin(int skin) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (_isComingSoon(skin)) { _showSnack('Coming soon!'); return; }
    if (progress.ownedSkins.contains(skin)) {
      await progress.setSelectedSkin(skin);
      return;
    }
    final price = _priceOf(skin);
    if (price == null) return;
    if (!await progress.spendCoins(price)) { _showSnack('Not enough coins'); return; }
    await progress.unlockSkin(skin);
    await progress.setSelectedSkin(0);
  }

  Future<void> _buyBoost(int price, Future<void> Function(int) grant) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (!await progress.spendCoins(price)) { _showSnack('Not enough coins'); return; }
    await grant(1);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.panelSolid,
        content: Text(text, style: AppTextStyles.body()),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          _ShopHeader(coins: progress.coins),

          // ── Tab bar ─────────────────────────────────────────────────
          Container(
            color: AppColors.concrete,
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.craneYellow, width: 3),
                ),
              ),
              labelColor: AppColors.craneYellow,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.button(size: 15),
              unselectedLabelStyle: AppTextStyles.body(size: 15),
              tabs: const [
                Tab(text: 'Brick Skins'),
                Tab(text: 'Power-Ups'),
              ],
            ),
          ),

          // ── Tab views ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SkinsTab(
                  isComingSoon: _isComingSoon,
                  priceOf: _priceOf,
                  buySkin: _buySkin,
                  setRandom: () {
                    AudioService.instance.playSfx(Sfx.buttonClick);
                    progress.setSelectedSkin(0);
                  },
                ),
                _PowerUpsTab(
                  buyBoost: _buyBoost,
                  craneBrakePrice: _craneBrakePrice,
                  blueprintRetryPrice: _blueprintRetryPrice,
                  goldRushPrice: _goldRushPrice,
                  hardHatPrice: _hardHatPrice,
                  concreteLockPrice: _concreteLockPrice,
                  steelFoundationPrice: _steelFoundationPrice,
                  foremanLuckPrice: _foremanLuckPrice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.concrete,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () {
                  AudioService.instance.playSfx(Sfx.buttonClick);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.text, size: 22),
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FORGE YARD',
                      style: AppTextStyles.body(size: 10, color: AppColors.craneYellow)
                          .copyWith(letterSpacing: 3.0)),
                  Text('Shop', style: AppTextStyles.title(size: 26)),
                ],
              ),

              const Spacer(),

              // Coin balance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.craneYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.craneYellow.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll_rounded,
                        color: AppColors.craneYellow, size: 20),
                    const SizedBox(width: 6),
                    Text('$coins',
                        style: AppTextStyles.button(
                            size: 17, color: AppColors.craneYellow)),
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

// ─── Skins tab ───────────────────────────────────────────────────────────────

class _SkinsTab extends StatelessWidget {
  const _SkinsTab({
    required this.isComingSoon,
    required this.priceOf,
    required this.buySkin,
    required this.setRandom,
  });
  final bool Function(int) isComingSoon;
  final int? Function(int) priceOf;
  final Future<void> Function(int) buySkin;
  final VoidCallback setRandom;

  @override
  Widget build(BuildContext context) {
    final isRandom = progress.selectedSkin == 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // 2×3 grid of skins
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, index) {
            final skin = index + 1;
            final owned = progress.ownedSkins.contains(skin);
            final selected = progress.selectedSkin == skin;
            final comingSoon = isComingSoon(skin);
            return _SkinTile(
              skin: skin,
              owned: owned,
              selected: selected,
              price: priceOf(skin),
              comingSoon: comingSoon,
              onTap: () => buySkin(skin),
            );
          },
        ),
        const SizedBox(height: 14),

        // Random shuffle toggle
        GestureDetector(
          onTap: setRandom,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: isRandom
                  ? AppColors.craneYellow.withValues(alpha: 0.15)
                  : AppColors.panelSolid,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRandom ? AppColors.craneYellow : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isRandom ? AppColors.craneYellow : AppColors.textMuted)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shuffle_rounded,
                      color: isRandom ? AppColors.craneYellow : AppColors.textMuted,
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Random Rotation',
                          style: AppTextStyles.button(
                              size: 16,
                              color: isRandom ? AppColors.craneYellow : AppColors.text)),
                      Text('Cycle through all owned skins each game',
                          style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (isRandom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.craneYellow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('ACTIVE',
                        style: AppTextStyles.body(
                            size: 11, color: AppColors.textDark)
                          .copyWith(letterSpacing: 1.0)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.price,
    required this.comingSoon,
    required this.onTap,
  });
  final int skin;
  final bool owned;
  final bool selected;
  final int? price;
  final bool comingSoon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.craneYellow
        : owned ? AppColors.cardBorder : Colors.white12;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panelSolid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.craneYellow.withValues(alpha: 0.25), blurRadius: 12)]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Opacity(
                      opacity: comingSoon ? 0.25 : 1,
                      child: Image.asset(TdbAssets.brick(skin), fit: BoxFit.contain),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _bottomColor(selected, owned, comingSoon),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: _bottomLabel(selected, owned, comingSoon, price),
                ),
              ],
            ),
            if (comingSoon)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white60, size: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _bottomColor(bool selected, bool owned, bool comingSoon) {
    if (selected) return AppColors.craneYellow.withValues(alpha: 0.25);
    if (owned) return AppColors.cardBorder.withValues(alpha: 0.3);
    if (comingSoon) return Colors.white.withValues(alpha: 0.04);
    return AppColors.brickRed.withValues(alpha: 0.15);
  }

  Widget _bottomLabel(bool selected, bool owned, bool comingSoon, int? price) {
    if (comingSoon) {
      return Text('Coming Soon',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 11, color: Colors.white38));
    }
    if (selected) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.craneYellow, size: 14),
        const SizedBox(width: 4),
        Text('EQUIPPED', style: AppTextStyles.body(size: 11, color: AppColors.craneYellow)
            .copyWith(letterSpacing: 1.0)),
      ]);
    }
    if (owned) {
      return Text('Tap to equip',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 11, color: AppColors.textMuted));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.toll_rounded, color: AppColors.craneYellow, size: 14),
      const SizedBox(width: 4),
      Text('${price ?? 0}',
          style: AppTextStyles.button(size: 14, color: AppColors.craneYellow)),
    ]);
  }
}

// ─── Power-ups tab ───────────────────────────────────────────────────────────

class _PowerUpsTab extends StatelessWidget {
  const _PowerUpsTab({
    required this.buyBoost,
    required this.craneBrakePrice,
    required this.blueprintRetryPrice,
    required this.goldRushPrice,
    required this.hardHatPrice,
    required this.concreteLockPrice,
    required this.steelFoundationPrice,
    required this.foremanLuckPrice,
  });

  final Future<void> Function(int, Future<void> Function(int)) buyBoost;
  final int craneBrakePrice;
  final int blueprintRetryPrice;
  final int goldRushPrice;
  final int hardHatPrice;
  final int concreteLockPrice;
  final int steelFoundationPrice;
  final int foremanLuckPrice;

  @override
  Widget build(BuildContext context) {
    final boosts = [
      _BoostDef(
        icon: Icons.speed_rounded,
        title: 'Crane Brake',
        subtitle: 'Slows the crane for 6 seconds at round start.',
        price: craneBrakePrice,
        owned: progress.slowHookBoosts,
        color: AppColors.craneYellow,
        onBuy: () => buyBoost(craneBrakePrice, progress.grantSlowHook),
      ),
      _BoostDef(
        icon: Icons.favorite_rounded,
        title: 'Blueprint Retry',
        subtitle: 'Survive one bad drop — keeps you in the rush.',
        price: blueprintRetryPrice,
        owned: progress.secondChanceBoosts,
        color: AppColors.danger,
        onBuy: () => buyBoost(blueprintRetryPrice, progress.grantSecondChance),
      ),
      _BoostDef(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Gold Rush',
        subtitle: 'Doubles coin rewards for your next game.',
        price: goldRushPrice,
        owned: progress.doubleCoinsBoosts,
        color: AppColors.craneYellow,
        onBuy: () => buyBoost(goldRushPrice, progress.grantDoubleCoins),
      ),
      _BoostDef(
        icon: Icons.construction_rounded,
        title: 'Hard Hat',
        subtitle: 'One bad placement is silently forgiven per game.',
        price: hardHatPrice,
        owned: progress.ghostBlockBoosts,
        color: AppColors.accent,
        onBuy: () => buyBoost(hardHatPrice, progress.grantGhostBlock),
      ),
      _BoostDef(
        icon: Icons.ac_unit_rounded,
        title: 'Concrete Lock',
        subtitle: 'Crane speed stays constant for the first 10 bricks.',
        price: concreteLockPrice,
        owned: progress.speedFreezeBoosts,
        color: const Color(0xFF4ECDC4),
        onBuy: () => buyBoost(concreteLockPrice, progress.grantSpeedFreeze),
      ),
      _BoostDef(
        icon: Icons.foundation_rounded,
        title: 'Steel Foundation',
        subtitle: 'Halves overlap requirement for the first 3 bricks.',
        price: steelFoundationPrice,
        owned: progress.wideBaseBoosts,
        color: const Color(0xFF95A5A6),
        onBuy: () => buyBoost(steelFoundationPrice, progress.grantWideBase),
      ),
      _BoostDef(
        icon: Icons.casino_rounded,
        title: "Foreman's Luck",
        subtitle: '+20 bonus coins when you complete a level.',
        price: foremanLuckPrice,
        owned: progress.luckyBoosts,
        color: AppColors.success,
        onBuy: () => buyBoost(foremanLuckPrice, progress.grantLucky),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: boosts.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BoostTile(def: boosts[i]),
    );
  }
}

class _BoostDef {
  const _BoostDef({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.owned,
    required this.color,
    required this.onBuy,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final int price;
  final int owned;
  final Color color;
  final VoidCallback onBuy;
}

class _BoostTile extends StatelessWidget {
  const _BoostTile({required this.def});
  final _BoostDef def;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: def.owned > 0
              ? def.color.withValues(alpha: 0.4)
              : AppColors.cardBorder.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Colored left accent bar
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: def.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: def.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(def.icon, color: def.color, size: 24),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(def.title, style: AppTextStyles.button(size: 15)),
                      if (def.owned > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: def.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: def.color.withValues(alpha: 0.6)),
                          ),
                          child: Text('×${def.owned}',
                              style: AppTextStyles.body(
                                  size: 11, color: def.color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(def.subtitle,
                      style: AppTextStyles.body(
                          size: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Buy button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PixelButton(
              label: '${def.price}',
              onPressed: def.onBuy,
              width: 82,
              height: 42,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
