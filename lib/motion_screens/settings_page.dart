import 'package:flutter/material.dart';
import 'package:motion/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_themes/app_strings.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppString.settingsTitle,
          style: TextEditingStyling.appTitleStyle,
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
            _SettingsOptions(
              onTap: (){},
              settingsTitle: AppString.downloadDataTitle,
              settingsDesciption: AppString.downloadDataDescription,),

            // notifications settings
            _SettingsOptions(
              onTap: () {},
              settingsTitle: AppString.notificationTitle,
              settingsDesciption: AppString.notificationDescription,
            ),

            // about motion
            _SettingsOptions(
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
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          subtitle: Text(
            themeValue.currentThemeModeName,
            style: Theme.of(context).textTheme.headlineMedium,),
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

// setting options list tile constructors
class _SettingsOptions extends StatelessWidget {
  final String settingsTitle;
  final String settingsDesciption;
  final VoidCallback onTap;

  const _SettingsOptions(
      {required this.settingsTitle,
      required this.settingsDesciption,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child:ListTile(
          onTap: onTap,
            title: Text(settingsTitle, style: Theme.of(context).textTheme.headlineLarge,),
            subtitle: Text(settingsDesciption, style: Theme.of(context).textTheme.headlineMedium,),
          ),
        );
  }
}