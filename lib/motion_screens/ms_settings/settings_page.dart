import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../ms_routes/about_page.dart';
import '../ms_reuse/screens_reusable.dart';

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
            style: AppTextStyle.leadingTextLTStyle(),
          ),
          subtitle: Text(
            themeValue.currentThemeModeName,
            style: AppTextStyle.settingSubtitleStyling,
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
