import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class SubcategoryRankIndicator extends StatelessWidget {
  const SubcategoryRankIndicator({
    super.key,
    required this.rankMovement,
    required this.isNewRank,
    this.periodLabel = 'today',
  });

  final int rankMovement;
  final bool isNewRank;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    if (isNewRank) {
      return Tooltip(
        message: 'Entered this ranking $periodLabel',
        child: const _RankMovementPill(
          icon: Icons.north_east_rounded,
          label: 'New',
          color: AppColor.accountedColor,
        ),
      );
    }

    if (rankMovement == 0) return const SizedBox.shrink();

    final movedUp = rankMovement > 0;
    final color = movedUp ? AppColor.accountedColor : Colors.redAccent;
    final places = rankMovement.abs();
    final placeLabel = places == 1 ? 'place' : 'places';

    return Tooltip(
      message: movedUp
          ? 'Moved up $places $placeLabel $periodLabel'
          : 'Moved down $places $placeLabel $periodLabel',
      child: _RankMovementPill(
        icon:
            movedUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        label: '$places',
        color: color,
      ),
    );
  }
}

class _RankMovementPill extends StatelessWidget {
  const _RankMovementPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 9.5,
              fontweight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
