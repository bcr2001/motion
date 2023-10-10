import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

// Custom widget for setting options list tiles
class SettingsOptions extends StatelessWidget {
  final String settingsTitle; // Title of the setting option
  final String settingsDesciption; // Description or additional info
  final VoidCallback? onTap; // Callback function when the tile is tapped
  final IconButton? trailing; // Widget to display at the end of the tile

  // Constructor for the SettingsOptions widget
  const SettingsOptions(
    this.trailing, {
    super.key,
    required this.settingsTitle,
    required this.settingsDesciption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        onTap: onTap, // Assign the onTap callback when the tile is tapped
        title: Text(
          settingsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Text(
          settingsDesciption,
          style: AppTextStyle.settingSubtitleStyling,
        ),
        trailing: trailing, // Assign the trailing widget
      ),
    );
  }
}
