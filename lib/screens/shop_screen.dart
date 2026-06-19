import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_orientation.dart';
import '../app/app_theme.dart';
import '../game/brick_unit.dart';
import '../game/unit_catalog.dart';
import '../game/unit_class.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../widgets/pixel_button.dart';
import '../widgets/unit_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  static const _commonCratePrice = 150; // coins
  static const _premiumCratePrice = 20; // gems

  static const _reinforcePrice = 80;
  static const _goldRushPrice = 100;
  static const _luckyPrice = 60;

  late final TabController _tabs;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    setOrientationsLockedPortrait();
    _tabs = TabController(length: 2, vsync: this);
    progress.addListener(_onChange);
  }

  @override
  void dispose() {
    progress.removeListener(_onChange);
    _tabs.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.panelSolid,
        content: Text(text, style: AppTextStyles.body()),
        duration: const Duration(seconds: 2),
      ));
  }

  Rarity _rollRarity(bool premium) {
    final weights = <Rarity, int>{
      for (final r in Rarity.values)
        r: premium ? _premiumWeight(r) : r.gachaWeight,
    };
    final total = weights.values.fold(0, (a, b) => a + b);
    var roll = _rng.nextInt(total);
    for (final entry in weights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return Rarity.common;
  }

  int _premiumWeight(Rarity r) {
    switch (r) {
      case Rarity.common:
        return 12;
      case Rarity.rare:
        return 46;
      case Rarity.epic:
        return 32;
      case Rarity.legendary:
        return 10;
    }
  }

  Future<void> _openCrate(bool premium) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (premium) {
      if (!await progress.spendGems(_premiumCratePrice)) {
        _snack('Not enough gems');
        return;
      }
    } else {
      if (!await progress.spendCoins(_commonCratePrice)) {
        _snack('Not enough coins');
        return;
      }
    }

    final rarity = _rollRarity(premium);
    final clazz = UnitClass.values[_rng.nextInt(UnitClass.values.length)];
    final def = unitDef(clazz, rarity);
    final isNew = await progress.grantUnit(def.id);
    AudioService.instance.playSfx(Sfx.unlock);
    if (!mounted) return;
    await _showReveal(def, isNew);
  }

  Future<void> _showReveal(UnitDef def, bool isNew) {
    final level = progress.unitLevel(def.id);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.panelSolid,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: def.rarity.color, width: 2),
            boxShadow: [
              BoxShadow(color: def.rarity.color.withValues(alpha: 0.5), blurRadius: 28),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isNew ? 'NEW UNIT!' : 'UPGRADED!',
                  style: AppTextStyles.headline(
                      size: 22, color: def.rarity.color)),
              const SizedBox(height: 14),
              SizedBox(
                width: 150,
                height: 200,
                child: UnitCard(def: def, level: level),
              ),
              const SizedBox(height: 8),
              if (!isNew)
                Text('Duplicate fused → Level $level',
                    style: AppTextStyles.body(
                        size: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              PixelButton(
                label: 'Nice!',
                width: 160,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buyBoost(int price, Future<void> Function(int) grant) async {
    AudioService.instance.playSfx(Sfx.buttonClick);
    if (!await progress.spendCoins(price)) {
      _snack('Not enough coins');
      return;
    }
    await grant(1);
    _snack('Purchased!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(coins: progress.coins, gems: progress.gems),
          Container(
            color: AppColors.concrete,
            child: TabBar(
              controller: _tabs,
              indicator: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.craneYellow, width: 3),
                ),
              ),
              labelColor: AppColors.craneYellow,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.button(size: 15),
              tabs: const [
                Tab(text: 'Crates'),
                Tab(text: 'Power-Ups'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CratesTab(
                  commonPrice: _commonCratePrice,
                  premiumPrice: _premiumCratePrice,
                  onOpen: _openCrate,
                ),
                _PowerUpsTab(
                  buyBoost: _buyBoost,
                  reinforcePrice: _reinforcePrice,
                  goldRushPrice: _goldRushPrice,
                  luckyPrice: _luckyPrice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coins, required this.gems});
  final int coins;
  final int gems;

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
                    border:
                        Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.text, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Text('Shop', style: AppTextStyles.title(size: 26)),
              const Spacer(),
              _Pill(icon: Icons.toll_rounded, color: AppColors.neonGold, value: '$coins'),
              const SizedBox(width: 8),
              _Pill(icon: Icons.diamond_rounded, color: AppColors.archer, value: '$gems'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.color, required this.value});
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(value, style: AppTextStyles.button(size: 15, color: color)),
        ],
      ),
    );
  }
}

class _CratesTab extends StatelessWidget {
  const _CratesTab({
    required this.commonPrice,
    required this.premiumPrice,
    required this.onOpen,
  });
  final int commonPrice;
  final int premiumPrice;
  final void Function(bool premium) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _CrateCard(
          title: 'Builder Crate',
          subtitle: 'A random unit. Mostly Common / Rare.',
          icon: Icons.inventory_2_rounded,
          color: AppColors.archer,
          priceIcon: Icons.toll_rounded,
          priceColor: AppColors.neonGold,
          price: commonPrice,
          onBuy: () => onOpen(false),
        ),
        const SizedBox(height: 14),
        _CrateCard(
          title: 'Foreman Crate',
          subtitle: 'Boosted odds for Epic & Legendary units.',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.rarityLegendary,
          priceIcon: Icons.diamond_rounded,
          priceColor: AppColors.archer,
          price: premiumPrice,
          onBuy: () => onOpen(true),
        ),
        const SizedBox(height: 20),
        Text('Duplicate units automatically fuse to raise that unit\'s level.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _CrateCard extends StatelessWidget {
  const _CrateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.priceIcon,
    required this.priceColor,
    required this.price,
    required this.onBuy,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final IconData priceIcon;
  final Color priceColor;
  final int price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.panelLight, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.button(size: 17)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: AppTextStyles.body(
                        size: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                PixelButton(
                  label: '$price',
                  icon: priceIcon,
                  width: 130,
                  height: 42,
                  fontSize: 15,
                  onPressed: onBuy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerUpsTab extends StatelessWidget {
  const _PowerUpsTab({
    required this.buyBoost,
    required this.reinforcePrice,
    required this.goldRushPrice,
    required this.luckyPrice,
  });

  final Future<void> Function(int, Future<void> Function(int)) buyBoost;
  final int reinforcePrice;
  final int goldRushPrice;
  final int luckyPrice;

  @override
  Widget build(BuildContext context) {
    final boosts = [
      _BoostDef(
        icon: Icons.shield_rounded,
        title: 'Reinforce',
        subtitle: 'Revive your tower once after a loss.',
        price: reinforcePrice,
        owned: progress.extraLifeBoosts,
        color: AppColors.danger,
        onBuy: () => buyBoost(reinforcePrice, progress.grantExtraLife),
      ),
      _BoostDef(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Gold Rush',
        subtitle: 'Doubles coin rewards for your next win.',
        price: goldRushPrice,
        owned: progress.doubleCoinsBoosts,
        color: AppColors.neonGold,
        onBuy: () => buyBoost(goldRushPrice, progress.grantDoubleCoins),
      ),
      _BoostDef(
        icon: Icons.casino_rounded,
        title: 'Lucky Charm',
        subtitle: '+20 bonus coins on every win.',
        price: luckyPrice,
        owned: progress.luckyBoosts,
        color: AppColors.success,
        onBuy: () => buyBoost(luckyPrice, progress.grantLucky),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: boosts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                          child: Text('x${def.owned}',
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
