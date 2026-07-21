import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

Future<DateTime?> showMotionDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Select Date',
  String confirmLabel = 'Select Date',
}) {
  var pendingDate = MotionDateUtils.dateOnly(initialDate);

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDarkMode = theme.brightness == Brightness.dark;
      final panelColor = isDarkMode
          ? AppColor.darkModeContentWidget
          : AppColor.lightModeContentWidget;
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;
      final borderColor =
          isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
      final maxHeight = MediaQuery.sizeOf(dialogContext).height - 32;

      return StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: panelColor,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 430,
              maxHeight: maxHeight.clamp(380.0, 620.0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColor.blueMainColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColor.blueMainColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 17,
                            fontweight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: Icon(Icons.close_rounded, color: secondaryText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColor.blueMainColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Selected',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 10.5,
                            fontweight: FontWeight.normal,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            MotionDateUtils.formatDisplayDate(pendingDate),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 12.5,
                              fontweight: FontWeight.w900,
                              color: AppColor.blueMainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.025)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: AppColor.blueMainColor,
                          onPrimary: Colors.white,
                          surface: panelColor,
                          onSurface: textColor,
                        ),
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: Colors.transparent,
                          headerBackgroundColor: Colors.transparent,
                          headerForegroundColor: textColor,
                          weekdayStyle: AppTextStyle.subSectionTextStyle(
                            fontsize: 10.5,
                            fontweight: FontWeight.w700,
                            color: secondaryText,
                          ),
                          dayStyle: AppTextStyle.subSectionTextStyle(
                            fontsize: 12,
                            fontweight: FontWeight.w700,
                          ),
                          dayBackgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColor.blueMainColor
                                  .withValues(alpha: 0.13);
                            }
                            return Colors.transparent;
                          }),
                          dayForegroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColor.blueMainColor;
                            }
                            if (states.contains(WidgetState.disabled)) {
                              return secondaryText.withValues(alpha: 0.35);
                            }
                            return textColor;
                          }),
                          dayShape: WidgetStateProperty.resolveWith((states) {
                            return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                              side: states.contains(WidgetState.selected)
                                  ? const BorderSide(
                                      color: AppColor.blueMainColor,
                                      width: 1.4,
                                    )
                                  : BorderSide.none,
                            );
                          }),
                          dayOverlayColor: WidgetStatePropertyAll(
                            AppColor.blueMainColor.withValues(alpha: 0.08),
                          ),
                          todayBackgroundColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          todayForegroundColor: const WidgetStatePropertyAll(
                            AppColor.blueMainColor,
                          ),
                          todayBorder: const BorderSide(
                            color: AppColor.blueMainColor,
                            width: 1.4,
                          ),
                          yearStyle: AppTextStyle.subSectionTextStyle(
                            fontsize: 13,
                            fontweight: FontWeight.w700,
                          ),
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: pendingDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        onDateChanged: (date) {
                          setDialogState(() => pendingDate = date);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: secondaryText,
                            minimumSize: const Size(0, 44),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(pendingDate),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.blueMainColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
