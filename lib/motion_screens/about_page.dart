import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import 'package:motion/motion_reusable/reuseable.dart';
import 'package:motion/motion_providers/theme_mode_provider.dart';
import 'package:motion/motion_themes/motion_text_styling.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("About Motion"),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.only(top: 20, right: 12, left: 12),
            child: Column(
              children: [
                // app logo
                currentSelectedThemeMode(context) == ThemeModeSettings.lightMode
                    ? SvgPicture.asset(
                        "assets/images/motion_icons/about_motion_logo_light.svg")
                    : SvgPicture.asset(
                        "assets/images/motion_icons/about_motion_logo.svg"),

                // app name
                const Text("Motion",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                // app version
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Text(
                    "Current App version 0.0.1.",
                    style: contentStyle(),
                  ),
                ),
                // app description
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    "Motion offers a user-friendly and effective solution for tracking and analyzing time, providing tools for seamless data collection, visual representation, and comprehensive reporting.",
                    textAlign: TextAlign.center,
                    style: contentStyle(),
                  ),
                ),

                // compant rights
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "${currentYear()} MOTION LLC. ALL RIGHTS RESERVED",
                        style: const TextStyle(
                            color: Color(0xFF00B0F0),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
