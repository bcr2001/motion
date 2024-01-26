import 'package:flutter/material.dart';

// contains all the colors used through out the app
class AppColor {
  // default heat map block color
  static const defaultHeatMapBlockColor = Color(0xFFDBDBDB);
  static const intensity5 = Color.fromRGBO(0, 255, 0, 0.11);
  static const intensity10 = Color.fromRGBO(0, 255, 0, 0.20);
  static const intensity15 = Color.fromRGBO(0, 140, 0, 0.38);
  static const intensity20 = Color.fromRGBO(0, 190, 0, 0.65);
  static const intensity25 = Color.fromRGBO(1, 154, 1, 1);

  // home page element background color
  static const tileBackgroundColor = Color(0xFF00A7A7);

  // accounted pie chart color (Annual Overview gallery page)
  static const Color galleryPieChartAccountedColor = Color(0xFF00E900);
  // unaccounted pie chart color (Annual Overview gallery page)
  static const Color galleryPieChartUnaccountedColor = Color(0xFF0096FF);

  // unaccounted pie section color
  static const Color unAccountedColor = Color(0xFF0191B4);

  // accounted pie section color
  static const Color accountedColor = Colors.greenAccent;

  // sleep color
  static const Color sleepPieChartColor = Colors.blueGrey;

  // education color
  static const Color educationPieChartColor = Color(0xFF80CA32);

  // skills color
  static const Color skillsPieChartColor = Color(0xFF9BA9B4);

  // entertainment color
  static const Color entertainmentPieChartColor = Color(0xFF287094);

  // personal growth color
  static const Color personalGrowthPieChartColor = Color(0xFF37AA85);

  // most tracked color
  static const Color mostTrackedBorderColor = Color(0XFF52D726);
  static const Color leastTrackedBorderColor = Color(0XFFFF0000);

  // dark theme widget background
  static const Color darkThemeWidgetBgColor = Color(0xFF1A1D26);

  // main app theme color
  static const Color blueMainColor = Color(0xFF00B0F0);

  // app content widget background color
  static const Color lightModeContentWidget = Color(0xFFF5F5FF);
  static const Color darkModeContentWidget = Color(0xFF1B2135);
}