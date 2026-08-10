import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_reusable/motion_ui/motion_date_picker_dialog.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../motion_core/motion_providers/shared_pvd/share.dart';
import '../ms_routes/about_page.dart';
import '../ms_reuse/screens_reusable.dart';
import 'data_transfer_page.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _showSetDateOfBirthDialog(BuildContext context) async {
    final userUid = context.read<UserUidProvider>().userUid;
    if (userUid == null || userUid.trim().isEmpty) {
      snackBarMessage(
        context,
        errorMessage: 'Your account is still loading.',
        requiresColor: true,
      );
      return;
    }

    final dateOfBirthStorage = DateOfBirthStorage();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(today.year - 120, 1, 1);
    final storedDate = await dateOfBirthStorage.getDateOfBirth(userUid);
    if (!context.mounted) return;

    final storedDay = storedDate == null
        ? null
        : DateTime(storedDate.year, storedDate.month, storedDate.day);
    final fallbackDate = DateTime(today.year - 25, today.month, today.day);
    final initialDate = storedDay != null &&
            !storedDay.isBefore(firstDate) &&
            !storedDay.isAfter(today)
        ? storedDay
        : fallbackDate;
    final selectedDate = await showMotionDatePickerDialog(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
      title: AppString.setDateOfBirthTitle,
      confirmLabel: 'Save Date',
    );
    if (selectedDate == null) return;

    await dateOfBirthStorage.saveDateOfBirth(userUid, selectedDate);
    if (!context.mounted) return;
    snackBarMessage(
      context,
      errorMessage: 'Date of birth saved',
      requiresColor: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppString.settingsTitle,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _ThemeModeSettingsOption(),

          // set date of birth
          SettingsOptions(
            null,
            settingsTitle: AppString.setDateOfBirthTitle,
            settingsDesciption: AppString.setDateOfBirthDescription,
            leadingIcon: Icons.cake_outlined,
            iconColor: AppColor.selfDevelopmentPieChartColor,
            onTap: () => _showSetDateOfBirthDialog(context),
          ),

          SettingsOptions(
            null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataTransferPage(),
                ),
              );
            },
            settingsTitle: AppString.downloadDataTitle,
            settingsDesciption: AppString.downloadDataDescription,
            leadingIcon: Icons.import_export,
            iconColor: AppColor.blueMainColor,
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
            leadingIcon: Icons.info_outline,
            iconColor: AppColor.unAccountedColor,
          ),
        ],
      ),
    );
  }
}

// (new) Theme Mode Settings Window
class _ThemeModeSettingsWindow extends StatelessWidget {
  const _ThemeModeSettingsWindow();

  // theme mode radio builder
  Widget themeRadio(
      {required BuildContext context,
      required int radioValue,
      required ValueChanged radioFunction,
      required int radioGroupValue,
      required String radioButtonName,
      required IconData icon}) {
    final isSelected = radioValue == radioGroupValue;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? AppColor.blueMainColor
        : isDarkMode
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black12;
    final tileColor = isSelected
        ? AppColor.blueMainColor.withValues(alpha: 0.10)
        : isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => radioFunction(radioValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColor.blueMainColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  radioButtonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w600,
                  ),
                ),
              ),
              Radio(
                  activeColor: AppColor.blueMainColor,
                  value: radioValue,
                  groupValue: radioGroupValue,
                  onChanged: radioFunction),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.themeSettingsTitle),
        centerTitle: true,
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Consumer<AppThemeModeProviderN1>(
              builder: (context, themeHandler2, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // theme mode selection
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        AppString.themeSettingPageMessage,
                        style: AppTextStyle.subSectionTextStyle(
                            fontsize: 12.5,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey),
                      ),
                    ),

                    // light mode radio button
                    themeRadio(
                        context: context,
                        radioValue: 1,
                        radioFunction: (value) {
                          Provider.of<AppThemeModeProviderN1>(context,
                                  listen: false)
                              .themeModeChanger(value);
                        },
                        radioGroupValue: themeHandler2.radioGroupValue,
                        radioButtonName: AppString.ligthMode,
                        icon: Icons.light_mode_outlined),

                    // dark  mode radio button
                    themeRadio(
                        context: context,
                        radioValue: 2,
                        radioFunction: (value) {
                          Provider.of<AppThemeModeProviderN1>(context,
                                  listen: false)
                              .themeModeChanger(value);
                        },
                        radioGroupValue: themeHandler2.radioGroupValue,
                        radioButtonName: AppString.darkMode,
                        icon: Icons.dark_mode_outlined),

                    // System  Default radio button
                    themeRadio(
                        context: context,
                        radioValue: 0,
                        radioFunction: (value) {
                          Provider.of<AppThemeModeProviderN1>(context,
                                  listen: false)
                              .themeModeChanger(value);
                        },
                        radioGroupValue: themeHandler2.radioGroupValue,
                        radioButtonName: AppString.systemDefault,
                        icon: Icons.brightness_auto_outlined)
                  ],
                );
              },
            )
          ]),
    );
  }
}

// theme mode settings option
class _ThemeModeSettingsOption extends StatelessWidget {
  const _ThemeModeSettingsOption();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeModeProviderN1>(
      builder: (context, themeValue, child) {
        String themeModeName =
            themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                ? AppString.ligthMode
                : themeValue.currentThemeMode == ThemeModeSettingsN1.darkMode
                    ? AppString.darkMode
                    : AppString.systemDefault;

        final themeIcon =
            themeValue.currentThemeMode == ThemeModeSettingsN1.lightMode
                ? Icons.light_mode_outlined
                : themeValue.currentThemeMode == ThemeModeSettingsN1.darkMode
                    ? Icons.dark_mode_outlined
                    : Icons.brightness_auto_outlined;

        return SettingsOptions(
          null,
          settingsTitle: AppString.themeTitle,
          settingsDesciption: themeModeName,
          leadingIcon: themeIcon,
          iconColor: AppColor.blueMainColor,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const _ThemeModeSettingsWindow()));
          },
        );
      },
    );
  }
}
