import "package:flutter/material.dart";
import 'package:motion/motion_reusable/reuseable.dart';
import 'package:motion/motion_providers/theme_pvd/theme_mode_provider.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/widget_bg_color.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppString.aboutMotionTitle),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                // app logo
                currentSelectedThemeMode(context) == ThemeModeSettings.lightMode
                    ? getSvgAsset("about_motion_logo_light.svg")
                    : getSvgAsset("about_motion_logo.svg"),

                // app name
                Text(AppString.motionTitle,
                    style:
                        TextStyle(color: blueMainColor,fontWeight: FontWeight.bold, fontSize: 25)),
                // app version
                const Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 5),
                  child: Text(
                    AppString.currentMotionVersion,
                  ),
                ),

                // app description
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(AppString.appDescription,
                    textAlign: TextAlign.center,
                  ),
                ),

                // compant rights
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "2023 ${AppString.motionLLC}",
                        style: Theme.of(context).textTheme.headlineLarge,
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
