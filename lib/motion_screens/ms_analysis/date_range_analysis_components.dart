import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class DateRangeAnalysisPanel extends StatelessWidget {
  final Widget child;

  const DateRangeAnalysisPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DateRangeSelectorPanel extends StatelessWidget {
  final String rangeLabel;
  final int selectedDays;
  final VoidCallback onSelectRange;

  const DateRangeSelectorPanel({
    super.key,
    required this.rangeLabel,
    required this.selectedDays,
    required this.onSelectRange,
  });

  @override
  Widget build(BuildContext context) {
    return DateRangeAnalysisPanel(
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColor.accountedColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.date_range_rounded,
              color: AppColor.accountedColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rangeLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$selectedDays day${selectedDays == 1 ? '' : 's'} selected',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Change range',
            child: IconButton.filledTonal(
              onPressed: onSelectRange,
              icon: const Icon(Icons.edit_calendar_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
