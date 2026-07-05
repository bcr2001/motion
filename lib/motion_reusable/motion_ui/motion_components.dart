import 'package:flutter/material.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class MotionPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  const MotionPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 14,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final resolvedBorderColor = borderColor ??
        (isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: resolvedBorderColor),
      ),
      child: child,
    );
  }
}

class MotionMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const MotionMetric({
    super.key,
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 10.5,
            fontweight: FontWeight.normal,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 13,
            fontweight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class MotionStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const MotionStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: fontSize,
          fontweight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class MotionProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const MotionProgressBar({
    super.key,
    required this.value,
    this.color = AppColor.blueMainColor,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.14),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class MotionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const MotionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 34,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 14,
                fontweight: FontWeight.w900,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 5),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MotionSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MotionSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.sectionTitleTextStyle(fontsize: 18).copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 11.5,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ],
    );
  }
}
