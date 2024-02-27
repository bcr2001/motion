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
  static sectionTitleTextStyle() {
    return _baseStyle.copyWith(fontSize: 17.5, fontWeight: FontWeight.w600);
  }

  // section title style (ef score)
  static sectionTitleTextStyleEF2() {
    return _baseStyle.copyWith(fontSize: 20.5, fontWeight: FontWeight.w600);
  }

  // section title style (subtitle)
  static subSectionTitleTextStyle() {
    return _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  }

  // section title style (main title)
  static specialSectionTitleTextStyle() {
    return _baseStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey);
  }

  // section title style (main title)
  static alertDialogElevatedButtonTextStyle() {
    return _baseStyle.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey);
  }

  // section title style
  static special1SectionTitleTextStyle() {
    return _baseStyle.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey);
  }

  // home page highlight element textStyle
  static TextStyle tileElementTextStyle() {
    return _baseStyle.copyWith(
        color: const Color.fromARGB(255, 232, 232, 232),
        fontSize: 11,
        fontWeight: FontWeight.w600);
  }

  // stats page highlight element textStyle
  static TextStyle statsElementTextStyle() {
    return _baseStyle.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600);
  }

  // stats page accounted and unaccounted gallary style
  static TextStyle accountedAndUnaccountedGallaryStyle() {
    return _baseStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5);
  }

  // stats page accounted and unaccounted gallary style
  static TextStyle overviewDataValueTextStyle() {
    return _baseStyle.copyWith(fontWeight: FontWeight.w500, fontSize: 13);
  }

  // home page subtitle list tile style
  static TextStyle subtitleLTStyle() {
    return _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  }

  // home page subtitle list tile style
  static TextStyle leadingTextLTStyle() {
    return _baseStyle.copyWith(fontSize: 14);
  }
  static TextStyle leadingTextLTStyle2() {
    return _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey);
  }
  static TextStyle leadingTextLTStyle3() {
    return _baseStyle.copyWith(fontSize: 12.5);
  }

  // home page subtitle list tile style
  static TextStyle leadingStatsTextLTStyle() {
    return _baseStyle.copyWith(fontSize: 12.5);
  }

  // home page subtitle list tile style
  static TextStyle trailingTextLTStyle() {
    return _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  }

  // home page subtitle list tile style
  static TextStyle navigationTextLTStyle() {
    return _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  }

  // home page tracking window information text style
  static TextStyle infoTextStyle() {
    return _baseStyle.copyWith(fontSize: 15);
  }

  // zen quote text styling
  static TextStyle quoteTextStyle() {
    return _baseStyle.copyWith(fontSize: 13);
  }

  // pie chart text styling
  static TextStyle pieChartTextStyling() {
    return _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  }

  // legend text style
  static TextStyle legendTextStyling() {
    return _baseStyle.copyWith(
        fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey);
  }

  // report page most and least tracked title style
  static TextStyle categoryTitleTextStyle() {
    return _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColor.blueMainColor);
  }

  // section information text style
  static TextStyle informationTextStyle() {
    return _baseStyle.copyWith(fontSize: 10);
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

  // account and unaccounted section style
  static TextStyle accountRegularAndUnaccountTextStyle() {
    return _baseStyle.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );
  }

  // most and least tracked style (totalHours)
  static TextStyle mostAndLestTextStyleTotalHours() {
    return _baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold);
  }

  // most and least tracked style (avergaeHours)
  static TextStyle mostAndLestTextStyleAverageHours() {
    return _baseStyle.copyWith(
      fontSize: 11,
    );
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

  // top and bottom information text style
  static TextStyle topAndBottomTextStyle() {
    return _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500);
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

  // category summary report (days)
  static TextStyle daysTextStyleCSR() {
    return _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: AppColor.tileBackgroundColor);
  }

  // category summary report (average)
  static TextStyle averageTextStyleCSR() {
    return _baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
  }

  // category summary report (hours)
  static TextStyle hoursTextStyleCSR() {
    return _baseStyle.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );
  }

  // result text style regular
  static TextStyle resultRegularTitleStyle() {
    return _baseStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 13);
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

  // dialog title text style
  static final TextStyle snackBarTextStyle = _baseStyle.copyWith(
    color: Colors.blue,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  // settings page subtitle fontstyle
  static final TextStyle settingSubtitleStyling =
      _baseStyle.copyWith(color: const Color(0xff777777), fontSize: 15);

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
