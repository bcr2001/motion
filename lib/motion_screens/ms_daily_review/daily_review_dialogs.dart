import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/tracking_time_policy.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class DailyTimeBlockDraft {
  const DailyTimeBlockDraft({
    required this.minutes,
    this.assignment,
  });

  final double minutes;
  final Assigner? assignment;
}

Future<DailyTimeBlockDraft?> showDailyTimeBlockDialog({
  required BuildContext context,
  required DateTime date,
  required List<Assigner> assignments,
  Subcategories? existingEntry,
}) {
  return showDialog<DailyTimeBlockDraft>(
    context: context,
    builder: (context) => _DailyTimeBlockDialog(
      date: date,
      assignments: assignments,
      existingEntry: existingEntry,
    ),
  );
}

Future<bool> showDeleteTimeBlockDialog({
  required BuildContext context,
  required Subcategories entry,
}) async {
  final parsedDate = MotionDateUtils.parseStoredDate(entry.date);
  final displayDate = parsedDate == null
      ? entry.date
      : MotionDateUtils.formatDisplayDate(parsedDate);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final surface = isDark
          ? AppColor.darkModeContentWidget
          : AppColor.lightModeContentWidget;
      final secondary = isDark ? Colors.white60 : Colors.blueGrey;
      final border = isDark ? Colors.white12 : Colors.black12;
      return Dialog(
        backgroundColor: surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
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
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Delete Time Block?',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 17,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${entry.subcategoryName} will be removed from $displayDate. '
                'Daily totals and XP will be recalculated.',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.normal,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        minimumSize: const Size(0, 44),
                        side: BorderSide(color: border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Delete'),
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

class _DailyTimeBlockDialog extends StatefulWidget {
  const _DailyTimeBlockDialog({
    required this.date,
    required this.assignments,
    this.existingEntry,
  });

  final DateTime date;
  final List<Assigner> assignments;
  final Subcategories? existingEntry;

  @override
  State<_DailyTimeBlockDialog> createState() => _DailyTimeBlockDialogState();
}

class _DailyTimeBlockDialogState extends State<_DailyTimeBlockDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  Assigner? _selectedAssignment;
  String? _error;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final totalSeconds = ((widget.existingEntry?.timeSpent ?? 0) * 60).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    _hoursController = TextEditingController(
      text: hours == 0 ? '' : '$hours',
    );
    _minutesController = TextEditingController(
      text: minutes == 0 ? '' : '$minutes',
    );
    _secondsController = TextEditingController(
      text: seconds == 0 ? '' : '$seconds',
    );
    if (widget.assignments.isNotEmpty) {
      _selectedAssignment = widget.assignments.first;
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _submit() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final seconds = int.tryParse(_secondsController.text.trim()) ?? 0;
    if (!_isEditing && _selectedAssignment == null) {
      setState(() => _error = 'Select a subcategory.');
      return;
    }
    if (hours < 0 ||
        hours > 24 ||
        minutes < 0 ||
        minutes > 59 ||
        seconds < 0 ||
        seconds > 59) {
      setState(() => _error = 'Use 0-24 hours and 0-59 minutes or seconds.');
      return;
    }
    final trackedMinutes = hours * 60 + minutes + seconds / 60;
    if (trackedMinutes <= 0) {
      setState(() => _error = 'Enter a time greater than zero.');
      return;
    }
    try {
      TrackingTimePolicy.validateBlock(trackedMinutes);
    } on TrackingTimeLimitException catch (error) {
      setState(() => _error = '$error');
      return;
    }
    Navigator.pop(
      context,
      DailyTimeBlockDraft(
        minutes: trackedMinutes,
        assignment: _selectedAssignment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;

    return Dialog(
      backgroundColor: surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            14 + MediaQuery.viewInsetsOf(context).bottom,
          ),
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
                      color: AppColor.blueMainColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_calendar_rounded
                          : Icons.add_alarm_rounded,
                      color: AppColor.blueMainColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Time Block' : 'Add Missing Time',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 17,
                            fontweight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MotionDateUtils.formatDisplayDate(widget.date),
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 10.5,
                            fontweight: FontWeight.normal,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: secondary),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (_isEditing)
                _SelectedActivity(entry: widget.existingEntry!)
              else
                DropdownButtonFormField<Assigner>(
                  initialValue: _selectedAssignment,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Subcategory',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: widget.assignments
                      .map(
                        (assignment) => DropdownMenuItem(
                          value: assignment,
                          child: Text(
                            '${assignment.subcategoryName} | ${assignment.mainCategoryName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAssignment = value),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _DurationField(
                    label: 'Hours',
                    controller: _hoursController,
                    hint: '00',
                  ),
                  const SizedBox(width: 8),
                  _DurationField(
                    label: 'Minutes',
                    controller: _minutesController,
                    hint: '00',
                  ),
                  const SizedBox(width: 8),
                  _DurationField(
                    label: 'Seconds',
                    controller: _secondsController,
                    hint: '00',
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        minimumSize: const Size(0, 44),
                        side: BorderSide(color: border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.blueMainColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(_isEditing ? 'Save Changes' : 'Add Time'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedActivity extends StatelessWidget {
  const _SelectedActivity({required this.entry});

  final Subcategories entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${entry.subcategoryName} | ${entry.mainCategoryName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 12.5,
          fontweight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        buildCounter: (
          _, {
          int? currentLength,
          bool? isFocused,
          int? maxLength,
        }) =>
            null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}
