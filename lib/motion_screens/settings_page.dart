import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:provider/provider.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // theme mode provider

  // theme mode settings option
  Widget themeModeSettings() {
    return Consumer<AppThemeModeProvider>(
        builder: (context, themeValue, child) {
      return ListTile(
        title: Text(
          "Theme",
          style: contentStyle,
        ),
        subtitle: Text(themeValue.currentThemeModeName),
        trailing: Switch(
          activeColor: const Color(0xFF00B0F0),
          value: themeValue.switchValue,
          onChanged: (value) {
            Provider.of<AppThemeModeProvider>(context, listen: false)
                .switchThemeModes(value);
          },
        ),
      );
    });
  }

  // other settings options builder
  Widget settingsOption({
    required String settingsName,
    required VoidCallback settingsFunction,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.5),
      child: GestureDetector(
        onTap: settingsFunction,
        child: Text(
          settingsName,
          style: contentStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: appTitleStyle,
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // theme mode settings
            themeModeSettings(),

            // download personal information settings
            settingsOption(
                settingsName: "Download Personal Data",
                settingsFunction: () {}),

            // notifications settings
            settingsOption(
                settingsName: "Notification", settingsFunction: () {}),

            // about motion
            settingsOption(
                settingsName: "About Motion", settingsFunction: () {})
          ],
        ),
      ),
    );
  }
}
