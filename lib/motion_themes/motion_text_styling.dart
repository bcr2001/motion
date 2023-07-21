import 'package:flutter/material.dart';

// route appbar title text style
const TextStyle   appTitleStyle =
     TextStyle(fontSize: 23, color: Color(0xFF00B0F0));

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

// dialog title text style
const dialogTitleTextStyle =
    TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.w600);
