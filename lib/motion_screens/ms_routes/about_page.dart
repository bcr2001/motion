import "package:flutter/material.dart";
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_core/motion_providers/theme_pvd/theme_mode_pvd.dart';
import 'package:motion/motion_themes/mth_app/app_images.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';

import '../../motion_themes/mth_styling/app_color.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _motionLogo(BuildContext context, bool isDarkMode) {
    return Container(
      height: 126,
      width: 126,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : AppColor.blueMainColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : AppColor.blueMainColor.withValues(alpha: 0.12),
        ),
      ),
      child: currentSelectedThemeMode(context) == ThemeModeSettingsN1.lightMode
          ? getSvgAsset("about_motion_logo_light.svg")
          : getSvgAsset("about_motion_logo.svg"),
    );
  }

  Widget _versionPill(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColor.accountedColor.withValues(alpha: 0.10)
            : AppColor.accountedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColor.accountedColor.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        AppString.currentMotionVersion,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 11,
          fontweight: FontWeight.w700,
          color: AppColor.accountedColor,
        ),
      ),
    );
  }

  Widget _infoPanel({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.045)
            : AppColor.blueMainColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.055),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: AppColor.blueMainColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 13,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppString.aboutMotionTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDarkMode ? 0.18 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _motionLogo(context, isDarkMode),
                        const SizedBox(height: 18),
                        Text(
                          AppString.motionTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.sectionTitleTextStyle(
                            fontsize: 28,
                          ).copyWith(
                            color: AppColor.blueMainColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _versionPill(isDarkMode),
                        const SizedBox(height: 16),
                        Text(
                          AppString.appDescription,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoPanel(
                    isDarkMode: isDarkMode,
                    icon: Icons.query_stats_rounded,
                    title: 'Track with context',
                    body:
                        'Motion helps turn daily time blocks into summaries, scores, and long-term patterns.',
                  ),
                  const SizedBox(height: 10),
                  _infoPanel(
                    isDarkMode: isDarkMode,
                    icon: Icons.emoji_events_rounded,
                    title: 'Progress that compounds',
                    body:
                        'XP, EFS, badges, streaks, and reports give your tracked time a clear sense of momentum.',
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "2023 ${AppString.motionLLC}",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
