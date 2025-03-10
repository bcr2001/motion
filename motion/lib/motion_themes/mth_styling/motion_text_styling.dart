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
  // BASE STYLE
  static final TextStyle _baseStyle = GoogleFonts.openSans(fontSize: 16.5);

  // chart label text style
  static chartLabelTextStyle() {
    return _baseStyle.copyWith(
      color: const Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
  }

  // section title style (main title)
  static sectionTitleTextStyle({double fontsize = 18}) {
    return _baseStyle.copyWith(fontSize: fontsize, fontWeight: FontWeight.w600);
  }

  // section title style (subtitle)
  static subSectionTextStyle(
      {double fontsize = 14,
      FontWeight fontweight = FontWeight.w600,
      Color? color}) {
    return _baseStyle.copyWith(
        fontSize: fontsize, fontWeight: fontweight, color: color);
  }

  // home page highlight element textStyle
  static TextStyle tileElementTextStyle({double? fontSize = 11}) {
    return _baseStyle.copyWith(
        color: AppColor.tileElementColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w600);
  }

  // stats page accounted and unaccounted gallary style
  static TextStyle accountedAndUnaccountedGallaryStyle({double fontsize = 14, FontWeight? fontweight = FontWeight.w600}) {
    return _baseStyle.copyWith(
        fontWeight: fontweight,
        fontSize: fontsize,
        color: AppColor.accountedColor);
  }


  // stats page Main Category Totals title
  static mainCategoryTotalTitle({double fontsize = 13}) {
    return _baseStyle.copyWith(
        color: AppColor.accountedColor,
        fontSize: fontsize,
        fontWeight: FontWeight.w600);
  }


  // account and unaccounted section style
  static TextStyle accountAndUnaccountTextStyle(bool isUnaccounted) {
    return _baseStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: isUnaccounted
            ? AppColor.unAccountedColor
            : AppColor.accountedColor);
  }

  // result title text style
  static TextStyle resultTitleStyle(bool isUnaccounted) {
    return _baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: isUnaccounted
            ? AppColor.unAccountedColor
            : AppColor.accountedColor);
  }

  // result title text style (home)
  static TextStyle resultTitleStyleHome(bool isUnaccounted) {
    return _baseStyle.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 12,
        color: isUnaccounted
            ? const Color(0xFFD30000)
            : AppColor.tileBackgroundColor);
  }

  // manual recording hint text style
  static TextStyle manualHintTextStyle(
      {double fontsize = 15, Color color = AppColor.manualHintTextColor}) {
    return _baseStyle.copyWith(
      fontSize: fontsize,
      color: color,
    );
  }


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
      color: isDarkMode ? darkModeTextColor.withValues(alpha: 0.6) : Colors.black54,
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