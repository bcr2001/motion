import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import '../../motion_core/motion_providers/shared_pvd/share.dart';
import '../ms_routes/about_page.dart';
import '../ms_reuse/screens_reusable.dart';
import 'package:date_picker_plus/date_picker_plus.dart';

// settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // date picker widget
  Widget _pickDateOfBirth() {
    final dateOfBirthStorage = DateOfBirthStorage();

    return Consumer<UserUidProvider>(
      builder: (context, user, child) {
        // user uid
        final userUID = user.userUid;

        return SizedBox(
          width: 400,
          height: 350,
          child: DatePicker(
            padding: EdgeInsets.zero,
            minDate: DateTime(1970, 1, 1),
            maxDate: DateTime(2100, 12, 31),
            daysOfTheWeekTextStyle: AppTextStyle.subSectionTextStyle(fontsize: 11, color: Colors.blueGrey),
            selectedCellTextStyle:
                AppTextStyle.accountedAndUnaccountedGallaryStyle(fontsize: 15),
            enabledCellsTextStyle: AppTextStyle.subSectionTextStyle(fontsize: 15, fontweight: FontWeight.normal),
            leadingDateTextStyle:
                AppTextStyle.accountedAndUnaccountedGallaryStyle(),
            onDateSelected: (value) async {
              logger.i("Date Of Birth: $value");

              await dateOfBirthStorage.saveDateOfBirth(userUID!, value);
            },
          ),
        );
      },
    );
  }

  // button to pop the alert dialog
  Widget _okayPopAlert(context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Text(
          AppString.okTitle,
          style: AppTextStyle.mainCategoryTotalTitle(fontsize: 15),
        ),
      ),
    );
  }

  // alert dialog that shows up when the user
  // clicks the Set Date of Birth option
  void _showSetDateOfBorthAlert(context) {
    // show the dob alert dialog
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialogConst(
              screenHeight: null,
              screenWidth: null,
              heightFactor: 0.45,
              alertDialogTitle: AppString.setDateOfBirthTitle,
              alertDialogContent: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // date of birth widget
                  _pickDateOfBirth(),
              
                  // button to confirm date of birth
                  Align(
                      alignment: Alignment.bottomRight,
                      child: _okayPopAlert(context))
                ],
              ));
        });
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
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // new theme mode window

            // theme mode settings
            const _ThemeModeSettingsOption(),

            // set date of birth
            SettingsOptions(
              null,
              settingsTitle: AppString.setDateOfBirthTitle,
              settingsDesciption: AppString.setDateOfBirthDescription,
              onTap: () => _showSetDateOfBorthAlert(context),
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

// (new) Theme Mode Settings Window
class _ThemeModeSettingsWindow extends StatelessWidget {
  const _ThemeModeSettingsWindow();

  // theme mode radio builder
  Widget themeRadio(
      {required int radioValue,
      required ValueChanged radioFunction,
      required int radioGroupValue,
      required String radioButtonName}) {
    return Row(
      children: [
        // radio button
        Radio(
            activeColor: AppColor.blueMainColor,
            value: radioValue,
            groupValue: radioGroupValue,
            onChanged: radioFunction),
        // radio button name
        Text(radioButtonName)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.themeSettingsTitle),
        centerTitle: true,
      ),
      body: Container(
          margin: const EdgeInsets.all(15.0),
          child: Consumer<AppThemeModeProviderN1>(
            builder: (context, themeHandler2, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // theme mode selection
                  Padding(
                    padding: const EdgeInsets.only(top: .0, bottom: 10.0),
                    child: Text(
                      AppString.themeSettingPageMessage,
                      style: AppTextStyle.subSectionTextStyle(fontsize: 12.5, fontweight: FontWeight.normal),
                    ),
                  ),

                  // light mode radio button
                  themeRadio(
                      radioValue: 1,
                      radioFunction: (value) {
                        Provider.of<AppThemeModeProviderN1>(context,
                                listen: false)
                            .themeModeChanger(value);
                      },
                      radioGroupValue: themeHandler2.radioGroupValue,
                      radioButtonName: AppString.ligthMode),

                  // dark  mode radio button
                  themeRadio(
                      radioValue: 2,
                      radioFunction: (value) {
                        Provider.of<AppThemeModeProviderN1>(context,
                                listen: false)
                            .themeModeChanger(value);
                      },
                      radioGroupValue: themeHandler2.radioGroupValue,
                      radioButtonName: AppString.darkMode),

                  // System  Default radio button
                  themeRadio(
                      radioValue: 0,
                      radioFunction: (value) {
                        Provider.of<AppThemeModeProviderN1>(context,
                                listen: false)
                            .themeModeChanger(value);
                      },
                      radioGroupValue: themeHandler2.radioGroupValue,
                      radioButtonName: AppString.systemDefault)
                ],
              );
            },
          )),
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const _ThemeModeSettingsWindow()));
          },
          child: ListTile(
              title: Text(
                AppString.themeTitle,
                style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14, fontweight: FontWeight.normal),
              ),
              subtitle: Text(
                themeModeName,
                style: AppTextStyle.manualHintTextStyle(),
              )),
        );
      },
    );
  }
}
