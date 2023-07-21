import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_themes/app_strings.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});


  // other settings options builder
  Widget settingsOption({
    required String settingsName,
    required VoidCallback settingsFunction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: GestureDetector(
        onTap: settingsFunction,
        child: Text(
          settingsName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppString.settingsTitle,
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
            const ThemeModeSettingsOption(),

            // download personal information settings
            settingsOption(
                settingsName: AppString.downloadDataTitle,
                settingsFunction: () {}),

            // notifications settings
            settingsOption(
                settingsName: AppString.notificationTitle, settingsFunction: () {}),

            // about motion
            settingsOption(
                settingsName: AppString.aboutMotionTitle,
                settingsFunction: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutPage()));
                })
          ],
        ),
      ),
    );
  }
}



// theme mode settings option
class ThemeModeSettingsOption extends StatelessWidget {
  const ThemeModeSettingsOption({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
      builder: (context, themeValue, child) {
        return ListTile(
          title: const Text(
            AppString.themeTitle,
          ),
          subtitle: Text(themeValue.currentThemeModeName),
          trailing: Switch(
            activeColor: const Color(0xFF00B0F0),
            value: themeValue.switchValue,
            onChanged: (value) {
              themeValue.switchThemeModes(value);
            },
          ),
        );
      },
    );
  }
}
