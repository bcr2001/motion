import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';
import 'screens_reusable.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppString.settingsTitle,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // theme mode settings
            const _ThemeModeSettingsOption(),

            // download personal information settings
            SettingsOptions(
              null,
              onTap: () {},
              settingsTitle: AppString.downloadDataTitle,
              settingsDesciption: AppString.downloadDataDescription,
            ),

            // notifications settings
            SettingsOptions(
              null,
              onTap: () {},
              settingsTitle: AppString.notificationTitle,
              settingsDesciption: AppString.notificationDescription,
            ),

            // about motion
            SettingsOptions(
              null,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const AboutPage()));
              },
              settingsTitle: AppString.aboutMotionTitle,
              settingsDesciption: AppString.aboutMotionDescription,
            ),
          ],
        ),
      ),
    );
  }
}

// theme mode settings option
class _ThemeModeSettingsOption extends StatelessWidget {
  const _ThemeModeSettingsOption();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProvider>(
      builder: (context, themeValue, child) {
        return ListTile(
          title: Text(
            AppString.themeTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          subtitle: Text(
            themeValue.currentThemeModeName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
