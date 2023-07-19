import 'package:flutter/material.dart';

// route appbar title text style
TextStyle appTitleStyle = const TextStyle(fontSize: 23, color: Color(0xFF00B0F0));

// content text style
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
