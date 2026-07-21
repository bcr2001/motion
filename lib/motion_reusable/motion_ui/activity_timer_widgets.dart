import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/timer_pvd/activity_timer_pvd.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class ActivityTimerCompactBar extends StatelessWidget {
  final VoidCallback onTap;

  const ActivityTimerCompactBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityTimerProvider>(
      builder: (context, timer, child) {
        final session = timer.session;
        if (session == null) return const SizedBox.shrink();

        final warning = timer.needsReview || timer.isReminderDue;
        final accent = warning ? Colors.orange : AppColor.blueMainColor;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final background = isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      timer.isRunning
                          ? Icons.timer_outlined
                          : Icons.pause_rounded,
                      size: 19,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.subcategoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 12.5,
                            fontweight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          warning
                              ? 'Check this timer'
                              : timer.isRunning
                                  ? 'Tracking now'
                                  : 'Timer paused',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 10.5,
                            fontweight: FontWeight.normal,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatActivityTimerDuration(timer.elapsedSeconds),
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 14,
                      fontweight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: accent, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
