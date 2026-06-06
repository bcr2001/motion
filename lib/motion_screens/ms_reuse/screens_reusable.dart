import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// Custom widget for setting options list tiles
class SettingsOptions extends StatelessWidget {
  final String settingsTitle; // Title of the setting option
  final String settingsDesciption; // Description or additional info
  final VoidCallback? onTap; // Callback function when the tile is tapped
  final Widget? trailing; // Widget to display at the end of the tile
  final IconData? leadingIcon;
  final Color? iconColor;

  // Constructor for the SettingsOptions widget
  const SettingsOptions(
    this.trailing, {
    super.key,
    required this.settingsTitle,
    required this.settingsDesciption,
    this.onTap,
    this.leadingIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final tileColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final accentColor = iconColor ?? AppColor.tileBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settingsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14,
                          fontweight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        settingsDesciption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.manualHintTextStyle(fontsize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
