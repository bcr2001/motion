import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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


class TextEditingStyling {
  // base styling
  static final TextStyle _baseStyle = GoogleFonts.openSans(fontSize: 16.5);

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

  // body styling
  static TextStyle bodyStyling(bool isDarkMode) {
    return _baseStyle.copyWith(
      color: isDarkMode ? darkModeTextColor : Colors.black,
    );
  }

  // headline (ListTile title) Large
  static TextStyle headingLarge(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 18,
      color: isDarkMode ? darkModeTextColor : Colors.black,
    );
  }

  // headline (ListTile title) Medium
  static TextStyle headingMedium(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 16,
      color: isDarkMode
          ? darkModeTextColor.withOpacity(0.6)
          : Colors.black54,
    );
  }


  // headline (Regular page titles) Medium
  static TextStyle headingSmall(bool isDarkMode) {
    return _baseStyle.copyWith(
      fontSize: 20,
      color: isDarkMode
          ? darkModeTextColor: Colors.black,
    );
  }
}