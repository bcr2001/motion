import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import '../motion_themes/mth_styling/app_color.dart';

// logger instance
var logger = Logger();

// // return current theme mode (dark or light theme)
ThemeModeSettingsN1 currentSelectedThemeMode(BuildContext context) {
  final selectedTheme = Provider.of<AppThemeModeProviderN1>(context);
  return selectedTheme.currentThemeMode;
}

// Circular progress indicator
Future circularIndicator(context) {
  return showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColor.blueMainColor,
          ),
        );
      });
}

// snack bar for sign in and sign out error messages
snackBarMessage(BuildContext context,
    {required String errorMessage, bool requiresColor = false}) {
  final snackBarTheme = Theme.of(context).snackBarTheme;

  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(milliseconds: 600),
    backgroundColor: snackBarTheme.backgroundColor,
    content: Text(
      errorMessage,
      style: requiresColor
          ? const TextStyle(color: Colors.red, fontSize: 14)
          : AppTextStyle
              .snackBarTextStyle, // Use the contentTextStyle from the theme.
    ),
  ));
}

// alart dialog
class AlertDialogConst extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final double? heightFactor;
  final double? widthFactor;
  final String alertDialogTitle;
  final Widget alertDialogContent;

  const AlertDialogConst(
      {super.key,
      required this.alertDialogTitle,
      required this.alertDialogContent,
      this.heightFactor = 0.23,
      this.widthFactor = 0.80,
      required this.screenHeight,
      required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      insetPadding: EdgeInsets.zero,
      title: Text(
        alertDialogTitle,
        style: AppTextStyle.sectionTitleTextStyle(),
      ),
      content: Builder(builder: (BuildContext context) {
        return SizedBox(
          height: screenHeight * heightFactor!,
          width: screenWidth * widthFactor!,
          child: alertDialogContent,
        );
      }),
    );
  }
}

class DynamicHeightAlertDialog extends StatelessWidget {
  final double maxHeightFactor; // Maximum height factor
  final double widthFactor;
  final String alertDialogTitle;
  final Widget alertDialogContent;

  const DynamicHeightAlertDialog({
    super.key,
    required this.alertDialogTitle,
    required this.alertDialogContent,
    this.maxHeightFactor = 0.5, // Default maximum height factor
    this.widthFactor = 0.80,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      insetPadding: EdgeInsets.zero,
      title:
          Text(alertDialogTitle, style: AppTextStyle.sectionTitleTextStyle()),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * maxHeightFactor, // Set the maximum height
        ),
        child: SingleChildScrollView(
          // Make it scrollable
          child: SizedBox(
            width: screenWidth * widthFactor,
            child: alertDialogContent,
          ),
        ),
      ),
    );
  }
}

// Custome List tile
class CustomeListTile1 extends StatelessWidget {
  final String leadingName;
  final String titleName;
  final String trailingName;

  const CustomeListTile1(
      {super.key, required this.leadingName, required this.titleName, required this.trailingName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        leadingName,
        style: AppTextStyle.leadingTextLTStyle3(),
      ),
      title: Container(
        width: 130,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColor.tileBackgroundColor),
        child: Center(
          child: Text(
            titleName,
            textAlign: TextAlign.center,
            style: AppTextStyle.tileElementTextStyle(),
          ),
        ),
      ),
      trailing: Text(
        trailingName,
        style: AppTextStyle.leadingTextLTStyle2(),
      ),
    );
  }
}
