import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';

// content text style (with color options)
TextStyle contentStyle(
    {double fontSize = 17,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.black}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

// main dark mode color
Color darkModeTextColor = const Color(0XFFF5F5F5);

class AppTextStyle {
  // base styling
  static final TextStyle _baseStyle = GoogleFonts.openSans(fontSize: 16.5);

  // account and unaccounted section style
  static TextStyle accountAndUnaccountTextStyle() {
    return _baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w600);
  }

  // result title text style
  static TextStyle resultTitleStyle(bool isUnaccounted) {
    return _baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color:
            isUnaccounted ? AppColor.unAccountedColor : AppColor.accountedColor);
  }

  // manual recording hint text style
  static TextStyle manualHintTextStyle() {
    return _baseStyle.copyWith(
      fontSize: 23,
      color: const Color(0xff777777),
    );
  }

  // route appbar title text style
  static final TextStyle appTitleStyle = _baseStyle.copyWith(
    color: const Color(0xFF00B0F0),
    fontSize: 23,
    fontWeight: FontWeight.w500,
  );

  // dialog title text style
  static final TextStyle dialogTitleTextStyle = _baseStyle.copyWith(
    color: Colors.blue,
    fontSize: 23,
    fontWeight: FontWeight.w700,
  );

  // settings page subtitle fontstyle
  static final TextStyle settingSubtitleStyling = _baseStyle.copyWith(
    color: const Color(0xff777777),
    fontSize: 15
  );

  // THEME DATA FONT STYLING

  // body styling (small)
  static TextStyle bodyStylingSmall(bool isDarkMode) {
    return _baseStyle.copyWith(
        color: isDarkMode ? darkModeTextColor : Colors.black, fontSize: 15);
  }

  // body styling (Medium)
  static TextStyle bodyStylingMedium(bool isDarkMode) {
    return _baseStyle.copyWith(
        color: isDarkMode ? darkModeTextColor : Colors.black, fontSize: 17);
  }

  // body styling (large)
  static TextStyle bodyStylingLarge(bool isDarkMode) {
    return _baseStyle.copyWith(
        color: isDarkMode ? darkModeTextColor : Colors.black, fontSize: 19);
  }

  // headline (ListTile title) Large
  static TextStyle headingLarge(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 23,
      color: isDarkMode ? darkModeTextColor : Colors.black,
    );
  }

  // headline (ListTile title) Medium
  static TextStyle headingMedium(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 20,
      color: isDarkMode ? darkModeTextColor.withOpacity(0.6) : Colors.black54,
    );
  }

  // headline (Regular page titles) Medium
  static TextStyle headingSmall(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 18,
      color: isDarkMode ? darkModeTextColor : Colors.black,
    );
  }
}
