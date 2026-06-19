import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../game/brick_unit.dart';
import '../game/unit_class.dart';
import 'unit_sprite.dart';

/// A collectible unit card with rarity frame, portrait, stats and level.
class UnitCard extends StatelessWidget {
  const UnitCard({
    super.key,
    required this.def,
    required this.level,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
    this.badge,
  });

  final UnitDef def;
  final int level;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  /// Optional small overlay badge (e.g. "In deck", count).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final rarityColor = def.rarity.color;
    final atk = def.attackAt(level);
    final hp = def.healthAt(level);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.panelLight,
                AppColors.card,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.craneYellow : rarityColor,
              width: selected ? 2.5 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: selected ? 0.5 : 0.25),
                blurRadius: selected ? 16 : 8,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Rarity stars row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: Row(
                      children: [
                        Icon(def.clazz.icon, size: 14, color: rarityColor),
                        const Spacer(),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < def.rarity.stars; i++)
                                  Icon(Icons.star_rounded,
                                      size: 11, color: rarityColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: UnitSprite(
                        clazz: def.clazz,
                        rarity: def.rarity,
                        size: 62,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      def.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.button(size: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Stat(
                            icon: Icons.bolt_rounded,
                            value: '$atk',
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          _Stat(
                            icon: Icons.favorite_rounded,
                            value: '$hp',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text('Lv$level',
                              style: AppTextStyles.body(
                                  size: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(top: 4, right: 4, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(value, style: AppTextStyles.body(size: 11, color: AppColors.text)),
      ],
    );
  }
}
