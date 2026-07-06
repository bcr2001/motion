import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/main.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_date_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_reusable/general_reuseable.dart';
import 'package:motion/motion_themes/mth_app/app_strings.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../motion_themes/mth_styling/app_color.dart';

part 'manual_tracking_widgets.dart';

// this returns the page where users can add data into the database tables
class ManualTimeRecordingRoute extends StatefulWidget {
  // main and subcategory names from the home page
  final String subcategoryName;
  final String mainCategoryName;

  const ManualTimeRecordingRoute(
      {super.key,
      required this.subcategoryName,
      required this.mainCategoryName});

  @override
  State<ManualTimeRecordingRoute> createState() =>
      _ManualTimeRecordingRouteState();
}

class _ManualTimeRecordingRouteState extends State<ManualTimeRecordingRoute> {
  static const String _pastEntriesStoragePrefix =
      'manualTrackingPastEntriesAdded';

  final _timeFormKey = GlobalKey<FormState>();
  final Set<int> _deletingBlockIds = {};
  final List<Subcategories> _pastEntriesAdded = [];
  String? _loadedPastEntriesKey;
  bool _hasChangedTrackedTime = false;

  // Text editing controllers for hours, minutes, and seconds input fields
  TextEditingController hourController = TextEditingController();
  TextEditingController minuteController = TextEditingController();
  TextEditingController secondController = TextEditingController();

  String _pastEntriesStorageKey({
    required String currentUser,
    required String currentDate,
  }) {
    return '$_pastEntriesStoragePrefix-$currentUser-$currentDate-${widget.subcategoryName}';
  }

  Map<String, dynamic> _pastEntryToJson(Subcategories entry) {
    return {
      'id': entry.id,
      'date': entry.date,
      'mainCategoryName': entry.mainCategoryName,
      'subcategoryName': entry.subcategoryName,
      'timeSpent': entry.timeSpent,
      'currentLoggedInUser': entry.currentLoggedInUser,
    };
  }

  Subcategories? _pastEntryFromJson(Map<String, dynamic> map) {
    final id = map['id'];
    if (id == null) return null;

    return Subcategories(
      id: id is int ? id : int.tryParse('$id'),
      date: map['date']?.toString() ?? '',
      mainCategoryName: map['mainCategoryName']?.toString() ?? '',
      subcategoryName: map['subcategoryName']?.toString() ?? '',
      timeSpent: map['timeSpent'] is num
          ? (map['timeSpent'] as num).toDouble()
          : double.tryParse('${map['timeSpent']}') ?? 0,
      currentLoggedInUser: map['currentLoggedInUser']?.toString() ?? '',
    );
  }

  Future<void> _restorePastEntriesAddedToday({
    required String currentUser,
    required String currentDate,
  }) async {
    final storageKey = _pastEntriesStorageKey(
      currentUser: currentUser,
      currentDate: currentDate,
    );
    if (_loadedPastEntriesKey == storageKey) return;
    _loadedPastEntriesKey = storageKey;

    final preferences = await SharedPreferences.getInstance();
    final encodedEntries = preferences.getStringList(storageKey) ?? const [];
    final restoredEntries = <Subcategories>[];

    for (final encodedEntry in encodedEntries) {
      try {
        final decodedEntry = jsonDecode(encodedEntry);
        if (decodedEntry is! Map<String, dynamic>) continue;

        final restoredEntry = _pastEntryFromJson(decodedEntry);
        if (restoredEntry == null ||
            restoredEntry.currentLoggedInUser != currentUser ||
            restoredEntry.subcategoryName != widget.subcategoryName ||
            restoredEntry.date == currentDate) {
          continue;
        }

        restoredEntries.add(restoredEntry);
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      final existingIds = _pastEntriesAdded
          .map((entry) => entry.id)
          .whereType<int>()
          .toSet();
      final entriesToAdd = restoredEntries
          .where((entry) => entry.id != null && existingIds.add(entry.id!))
          .toList();
      _pastEntriesAdded.addAll(entriesToAdd);
    });
  }

  Future<void> _rememberPastEntryAddedToday({
    required Subcategories entry,
    required String currentDate,
  }) async {
    if (entry.id == null) return;

    final storageKey = _pastEntriesStorageKey(
      currentUser: entry.currentLoggedInUser,
      currentDate: currentDate,
    );
    final preferences = await SharedPreferences.getInstance();
    final existingEntries = preferences.getStringList(storageKey) ?? const [];
    final nextEntries = <String>[];
    final seenIds = <int>{};

    for (final encodedEntry in existingEntries) {
      try {
        final decodedEntry = jsonDecode(encodedEntry);
        if (decodedEntry is! Map<String, dynamic>) continue;

        final existingEntry = _pastEntryFromJson(decodedEntry);
        final existingId = existingEntry?.id;
        if (existingEntry == null ||
            existingId == null ||
            existingEntry.date == currentDate ||
            !seenIds.add(existingId)) {
          continue;
        }

        nextEntries.add(encodedEntry);
      } catch (_) {
        continue;
      }
    }

    if (seenIds.add(entry.id!)) {
      nextEntries.insert(0, jsonEncode(_pastEntryToJson(entry)));
    }

    await preferences.setStringList(storageKey, nextEntries);
  }

  Future<void> _forgetPastEntryAddedToday({
    required Subcategories entry,
    required String currentDate,
  }) async {
    final entryId = entry.id;
    if (entryId == null) return;

    final storageKey = _pastEntriesStorageKey(
      currentUser: entry.currentLoggedInUser,
      currentDate: currentDate,
    );
    final preferences = await SharedPreferences.getInstance();
    final existingEntries = preferences.getStringList(storageKey) ?? const [];
    final nextEntries = <String>[];

    for (final encodedEntry in existingEntries) {
      try {
        final decodedEntry = jsonDecode(encodedEntry);
        if (decodedEntry is! Map<String, dynamic>) continue;

        final existingEntry = _pastEntryFromJson(decodedEntry);
        if (existingEntry?.id == entryId) continue;

        nextEntries.add(encodedEntry);
      } catch (_) {
        continue;
      }
    }

    await preferences.setStringList(storageKey, nextEntries);
  }

  Future<void> _resetDailyXpTargetCelebration(Subcategories block) async {
    if (block.currentLoggedInUser.isEmpty || block.date.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final celebrationKey =
        'daily_xp_target_celebration_v4_${block.currentLoggedInUser}-${block.date}';
    await prefs.remove(celebrationKey);
    debugLog(
      'XP TARGET CELEBRATION DIRECT: reset shown state after deleting a tracked block for ${block.date}.',
    );
  }

  @override
  void dispose() {
    // Dispose of the text editing controllers to prevent memory leaks
    hourController.dispose();
    minuteController.dispose();
    secondController.dispose();

    super.dispose();
  }

  // time component
  Widget _titleAndTextFieldBuilder(
      {required String title,
      required TextEditingController textEditingController}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final inputColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.035);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // time component titles
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),

            const SizedBox(height: 4),

            // text field for each time component
            TextFormField(
              controller: textEditingController,
              keyboardType: TextInputType.number,
              maxLength: 2,
              buildCounter: (BuildContext context,
                      {int? currentLength,
                      int? maxLength,
                      bool? isFocused}) =>
                  null,
              textAlign: TextAlign.center,
              cursorColor: AppColor.blueMainColor,
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 24),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "00",
                hintStyle: AppTextStyle.manualHintTextStyle(fontsize: 24),
              ),
              validator: (value) {
                // check whether the field is empty
                if (value == null || value.isEmpty) {
                  return "??";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeEntryBlock() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColor.blueMainColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.subcategoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // time component text fields displayed
          Row(
            children: [
              // hour time component
              _titleAndTextFieldBuilder(
                  title: "Hours", textEditingController: hourController),

              const SizedBox(width: 8),

              // minute time component
              _titleAndTextFieldBuilder(
                  title: "Minutes", textEditingController: minuteController),

              const SizedBox(width: 8),

              // seconds time component
              _titleAndTextFieldBuilder(
                  title: "Seconds", textEditingController: secondController)
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackingDateSelector({
    required DateTime selectedDate,
    required VoidCallback onTap,
  }) {
    final today = MotionDateUtils.today();
    final isToday = MotionDateUtils.isSameDate(selectedDate, today);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isToday
        ? AppColor.blueMainColor.withValues(alpha: 0.08)
        : Colors.orange.withValues(alpha: isDarkMode ? 0.12 : 0.08);
    final accentColor = isToday ? AppColor.blueMainColor : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  size: 19, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isToday ? 'Tracking date' : 'Adding to a past date',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MotionDateUtils.formatDisplayDate(selectedDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 13,
                        fontweight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _selectTrackingDate({
    required BuildContext context,
    required DateTime selectedDate,
    required DateTime today,
  }) async {
    var pendingDate = selectedDate;

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        final isDarkMode =
            Theme.of(dialogContext).brightness == Brightness.dark;
        final surfaceColor = isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;
        final borderColor =
            isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final mediaQuery = MediaQuery.of(dialogContext);
            final maxDialogHeight = mediaQuery.size.height -
                mediaQuery.viewInsets.bottom -
                mediaQuery.padding.top -
                mediaQuery.padding.bottom -
                40;

            return Dialog(
              backgroundColor: surfaceColor,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: maxDialogHeight.clamp(360.0, 620.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                              color: AppColor.blueMainColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColor.blueMainColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Tracking Date',
                                  style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 17,
                                    fontweight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose today or an earlier date',
                                  style: AppTextStyle.subSectionTextStyle(
                                    fontsize: 10.5,
                                    fontweight: FontWeight.normal,
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColor.blueMainColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(13),
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
                            const Spacer(),
                            Text(
                              MotionDateUtils.formatDisplayDate(pendingDate),
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 12.5,
                                fontweight: FontWeight.w900,
                                color: AppColor.blueMainColor,
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
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: borderColor),
                        ),
                        child: Theme(
                          data: Theme.of(dialogContext).copyWith(
                            colorScheme:
                                Theme.of(dialogContext).colorScheme.copyWith(
                                      primary: AppColor.blueMainColor,
                                      onPrimary: Colors.white,
                                      surface: surfaceColor,
                                      onSurface: textColor,
                                    ),
                            datePickerTheme: DatePickerThemeData(
                              backgroundColor: Colors.transparent,
                              headerBackgroundColor: Colors.transparent,
                              headerForegroundColor: textColor,
                              weekdayStyle:
                                  AppTextStyle.subSectionTextStyle(
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
                                      .withValues(alpha: 0.14);
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
                              dayShape:
                                  WidgetStateProperty.resolveWith((states) {
                                return RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColor.blueMainColor
                                      .withValues(alpha: 0.14);
                                }
                                return Colors.transparent;
                              }),
                              todayForegroundColor:
                                  const WidgetStatePropertyAll(
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
                            firstDate: DateTime(2021, 7, 1),
                            lastDate: today,
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
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: secondaryText,
                                minimumSize: const Size(0, 44),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(dialogContext)
                                  .pop(pendingDate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.blueMainColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Select Date'),
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
      },
    );
  }

  Future<bool> _confirmHistoricalEntry({
    required BuildContext context,
    required DateTime selectedDate,
    required double minutes,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (confirmationContext) {
        final isDarkMode =
            Theme.of(confirmationContext).brightness == Brightness.dark;
        final panelColor = isDarkMode
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget;
        final borderColor =
            isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
        final secondaryText = isDarkMode ? Colors.white60 : Colors.blueGrey;

        return Dialog(
          backgroundColor: panelColor,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Add Past Time?',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 17,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subcategoryName,
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 14,
                          fontweight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${convertMinutesToTime(minutes)} on '
                        '${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 12,
                          fontweight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Daily totals, XP, and streak history for this date will be '
                  'recalculated.',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11.5,
                    fontweight: FontWeight.normal,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(confirmationContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondaryText,
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(confirmationContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.blueMainColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Time'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Widget _todaysBlocksPanel({
    required List<Subcategories> blocks,
    required SubcategoryTrackerDatabaseProvider subs,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final totalMinutes = blocks.fold<double>(
        0.0, (previousValue, item) => previousValue + item.timeSpent);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackedBlocksHeader(
            title: AppString.blockTitle,
            emptyLabel: 'No time blocks added yet',
            blockCount: blocks.length,
            totalMinutes: totalMinutes,
            icon: Icons.event_note_outlined,
          ),
          if (blocks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                "No time blocks added yet",
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
            )
          else
            ...blocks.asMap().entries.map((entry) {
              final block = entry.value;
              final convertedTimeRecorded =
                  convertMinutesToTime(block.timeSpent);

              return _TrackedBlockTile(
                index: entry.key,
                convertedTimeRecorded: convertedTimeRecorded,
                isDeleting:
                    block.id != null && _deletingBlockIds.contains(block.id),
                onDelete: () async {
                  final blockId = block.id;
                  if (blockId == null || _deletingBlockIds.contains(blockId)) {
                    return;
                  }

                  setState(() => _deletingBlockIds.add(blockId));
                  try {
                    await subs.deleteSubcategoryEntry(
                      blockId,
                      deletedSubcategory: block,
                    );
                    _hasChangedTrackedTime = true;
                    await _resetDailyXpTargetCelebration(block);
                    context
                        .read<ExperiencePointTableProvider>()
                        .refreshExperiencePointViews();
                  } finally {
                    if (mounted) {
                      setState(() => _deletingBlockIds.remove(blockId));
                    }
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _pastEntriesPanel({
    required SubcategoryTrackerDatabaseProvider subs,
    required String currentDate,
  }) {
    if (_pastEntriesAdded.isEmpty) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final totalMinutes = _pastEntriesAdded.fold<double>(
      0,
      (total, block) => total + block.timeSpent,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackedBlocksHeader(
            title: 'Past Entries Added',
            emptyLabel: 'No past entries added',
            blockCount: _pastEntriesAdded.length,
            totalMinutes: totalMinutes,
            icon: Icons.history_rounded,
            accentColor: Colors.orange,
          ),
          ..._pastEntriesAdded.asMap().entries.map((entry) {
            final block = entry.value;
            final parsedDate = MotionDateUtils.parseStoredDate(block.date);
            final dateLabel = parsedDate == null
                ? block.date
                : MotionDateUtils.formatDisplayDate(parsedDate);

            return _TrackedBlockTile(
              index: entry.key,
              convertedTimeRecorded: convertMinutesToTime(block.timeSpent),
              subtitle: dateLabel,
              isDeleting:
                  block.id != null && _deletingBlockIds.contains(block.id),
              onDelete: () async {
                final blockId = block.id;
                if (blockId == null || _deletingBlockIds.contains(blockId)) {
                  return;
                }

                setState(() => _deletingBlockIds.add(blockId));
                try {
                  await subs.deleteSubcategoryEntry(
                    blockId,
                    deletedSubcategory: block,
                  );
                  await _forgetPastEntryAddedToday(
                    entry: block,
                    currentDate: currentDate,
                  );
                  if (mounted) {
                    setState(() => _pastEntriesAdded.remove(block));
                  }
                } finally {
                  if (mounted) {
                    setState(() => _deletingBlockIds.remove(blockId));
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  // alert dialog that is displayed when the add icon is clicked
  void _showTimeAlertDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final today = MotionDateUtils.today();
    var selectedDate = DateTime(today.year, today.month, today.day);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          var isAddingBlock = false;
          var subTrackerProvider =
              context.read<SubcategoryTrackerDatabaseProvider>();

          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialogConst(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
                heightFactor: 0.37,
                alertDialogTitle: AppString.manualAddBlock,
                alertDialogContent: Form(
                  key: _timeFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _trackingDateSelector(
                        selectedDate: selectedDate,
                        onTap: () async {
                          FocusScope.of(dialogContext).unfocus();
                          final pickedDate = await _selectTrackingDate(
                            context: dialogContext,
                            selectedDate: selectedDate,
                            today:
                                DateTime(today.year, today.month, today.day),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      _timeEntryBlock(),

                      const SizedBox(height: 16),

                      // cancel and add button
                      Consumer<UserUidProvider>(
                        builder: (context, uid, child) {
                          return _ManualTrackingTimeDialogActions(
                            onCancel: () {
                              // exits the alart dialog and resets the text
                              // contoller content
                              navigationKey.currentState!.pop();

                              hourController.text = "";
                              minuteController.text = "";
                              secondController.text = "";
                            },
                            onAdd: () async {
                              if (isAddingBlock) {
                                return;
                              }

                              final currentUser = uid.userUid;
                              if (currentUser == null) {
                                snackBarMessage(context,
                                    errorMessage:
                                        AppString.firebaseSomethingWentWrong,
                                    requiresColor: true);
                                return;
                              }

                              // adds the necessary data to the subcategory
                              // table if validation passes
                              if (_timeFormKey.currentState!.validate()) {
                                _timeFormKey.currentState!.save();
                                var shouldCloseDialog = false;

                                // checks whether the text the user passes into the
                                // text fields are indeed values and not strings
                                try {
                                  if (hourController.text.contains('.') ||
                                      minuteController.text.contains('.') ||
                                      secondController.text.contains('.') ||
                                      hourController.text.contains('-') ||
                                      minuteController.text.contains('-') ||
                                      secondController.text.contains('-')) {
                                    // if either texts contains "." or "-" then
                                    // the error message below will pop up
                                    snackBarMessage(context,
                                        errorMessage:
                                            AppString.manualInvalidValueError,
                                        requiresColor: true);

                                    logger.e("Invald use of a dot");
                                  }
                                  // checks whether the values entered fall within
                                  // a specific range, if not then an error message
                                  // will be displayed
                                  else if (int.parse(hourController.text) >
                                          25 ||
                                      int.parse(minuteController.text) > 59 ||
                                      int.parse(secondController.text) > 59) {
                                    // snack bar that alerts the user when the
                                    // entries are out of range
                                    snackBarMessage(context,
                                        errorMessage:
                                            AppString.manualRangeValueError,
                                        requiresColor: true);
                                    debugLog("Failed Validation");
                                  } else {
                                    debugLog("Passed Validation");
                                    final selectedDateIso =
                                        MotionDateUtils.formatDbDate(
                                      selectedDate,
                                    );
                                    final enteredMinutes = timeAdder(
                                      h: hourController.text,
                                      m: minuteController.text,
                                      s: secondController.text,
                                    );

                                    if (enteredMinutes <= 0) {
                                      snackBarMessage(
                                        context,
                                        errorMessage:
                                            'Enter a time greater than zero',
                                        requiresColor: true,
                                      );
                                      return;
                                    }

                                    final isHistorical =
                                        selectedDate.isBefore(today);
                                    if (isHistorical) {
                                      final confirmed =
                                          await _confirmHistoricalEntry(
                                        context: dialogContext,
                                        selectedDate: selectedDate,
                                        minutes: enteredMinutes,
                                      );
                                      if (!confirmed) return;
                                    }

                                    setDialogState(
                                        () => isAddingBlock = true);

                                    final subcategory = Subcategories(
                                        date: selectedDateIso,
                                        mainCategoryName:
                                            widget.mainCategoryName,
                                        subcategoryName: widget.subcategoryName,
                                        currentLoggedInUser: currentUser,
                                        timeSpent: enteredMinutes);

                                    final insertedId =
                                        await subTrackerProvider
                                            .insertIntoSubcategoryTable(
                                                subcategory);
                                    subcategory.id = insertedId;
                                    _hasChangedTrackedTime = true;
                                    context
                                        .read<ExperiencePointTableProvider>()
                                        .refreshExperiencePointViews();
                                    if (isHistorical && mounted) {
                                      await _rememberPastEntryAddedToday(
                                        entry: subcategory,
                                        currentDate:
                                            MotionDateUtils.formatDbDate(
                                          today,
                                        ),
                                      );
                                      setState(() {
                                        _pastEntriesAdded.insert(
                                            0, subcategory);
                                      });
                                    }
                                    shouldCloseDialog = true;

                                    hourController.text = "";
                                    minuteController.text = "";
                                    secondController.text = "";
                                  }
                                } finally {
                                  if (!shouldCloseDialog && context.mounted) {
                                    setDialogState(
                                        () => isAddingBlock = false);
                                  }
                                }

                                if (shouldCloseDialog) {
                                  navigationKey.currentState!.pop();
                                }
                              }
                            },
                            isBusy: isAddingBlock,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChangedTrackedTime);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChangedTrackedTime),
          ),
          // the selected subcategory displayed as app bar title
          title: Text(widget.subcategoryName),
          centerTitle: true,
          actions: [
            // alert dialog to record time
            IconButton(
                onPressed: () => _showTimeAlertDialog(context),
                icon: const Icon(Icons.add))
          ],
        ),
        body: SingleChildScrollView(
          child: Consumer3<
              SubcategoryTrackerDatabaseProvider,
              CurrentDateProvider,
              UserUidProvider>(builder: (context, subs, date, user, child) {
            final currentUser = user.userUid;
            if (currentUser == null) {
              return userLoadingIndicator();
            }
            _restorePastEntriesAddedToday(
              currentUser: currentUser,
              currentDate: date.currentDate,
            );

            return CachedFutureBuilder<List<Subcategories>>(
              cacheKey:
                  'manual-blocks-$currentUser-${date.currentDate}-${widget.subcategoryName}-'
                  '${subs.refreshKeyForDate(currentUser: currentUser, date: date.currentDate)}',
              futureFactory: () => subs.retrieveCurrentDateSubcategories(
                date.currentDate,
                currentUser,
                widget.subcategoryName,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColor.blueMainColor,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final blocks = snapshot.data ?? const <Subcategories>[];
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: _todaysBlocksPanel(
                        blocks: blocks,
                        subs: subs,
                      ),
                    ),
                    _pastEntriesPanel(
                      subs: subs,
                      currentDate: date.currentDate,
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
