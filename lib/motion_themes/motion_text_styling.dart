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

class TextEditingStyling {
  // route appbar title text style
  static final TextStyle appTitleStyle = GoogleFonts.openSans(
      fontSize: 23,
      color: const Color(0xFF00B0F0),
      fontWeight: FontWeight.w500);

  // dialog title text style
  static final TextStyle dialogTitleTextStyle = GoogleFonts.openSans(
      color: Colors.blue, fontSize: 23, fontWeight: FontWeight.w700);

  // body styling (light mode)
  static final TextStyle bodyStylingLightMode =
      GoogleFonts.openSans(color: Colors.black, fontSize: 16.5);

  // body styling (dark mode)
  static final TextStyle bodyStylingDarkMode =
      GoogleFonts.openSans(color:const Color(0XFFF5F5F5), fontSize: 16.5);
}
