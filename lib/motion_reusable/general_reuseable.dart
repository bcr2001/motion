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
snackBarMessage(BuildContext context, {required String errorMessage, bool requiresColor = false}) {
  final snackBarTheme = Theme.of(context).snackBarTheme;

  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(milliseconds: 600),
    backgroundColor: snackBarTheme.backgroundColor,
    content: Text(
      errorMessage,
      style: requiresColor? const TextStyle(
        color: Colors.red,
        fontSize: 14
      ) 
      : AppTextStyle.snackBarTextStyle, // Use the contentTextStyle from the theme.
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
      title: Text(alertDialogTitle, style: AppTextStyle.sectionTitleTextStyle(),),
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
