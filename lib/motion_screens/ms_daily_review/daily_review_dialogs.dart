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
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : Colors.black.withValues(alpha: 0.028);

    return Dialog(
      backgroundColor: surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DailyTimeBlockDialogHeader(
                isEditing: _isEditing,
                date: widget.date,
                secondaryColor: secondary,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 19),
              const _DailyDialogSectionLabel(
                icon: Icons.category_outlined,
                label: 'Activity',
              ),
              const SizedBox(height: 8),
              if (_isEditing)
                _SelectedActivity(entry: widget.existingEntry!)
              else
                DropdownButtonFormField<Assigner>(
                  initialValue: _selectedAssignment,
                  isExpanded: true,
                  isDense: false,
                  itemHeight: 58,
                  menuMaxHeight: 320,
                  dropdownColor: surface,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColor.blueMainColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldFill,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColor.blueMainColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                  items: widget.assignments
                      .map(
                        (assignment) => DropdownMenuItem(
                          value: assignment,
                          child: _AssignmentOption(assignment: assignment),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedAssignment = value;
                    _error = null;
                  }),
                ),
              const SizedBox(height: 17),
              const _DailyDialogSectionLabel(
                icon: Icons.timer_outlined,
                label: 'Duration',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    _DurationField(
                      label: 'Hours',
                      controller: _hoursController,
                      hint: '00',
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(width: 8),
                    _DurationField(
                      label: 'Minutes',
                      controller: _minutesController,
                      hint: '00',
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(width: 8),
                    _DurationField(
                      label: 'Seconds',
                      controller: _secondsController,
                      hint: '00',
                      onChanged: (_) => _clearError(),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DailyDialogErrorMessage(message: _error!),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        minimumSize: const Size(0, 46),
                        side: BorderSide(color: border),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.blueMainColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(_isEditing ? 'Save Changes' : 'Add Time'),
                          ],
                        ),
                      ),
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

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}

class _DailyTimeBlockDialogHeader extends StatelessWidget {
  const _DailyTimeBlockDialogHeader({
    required this.isEditing,
    required this.date,
    required this.secondaryColor,
    required this.onClose,
  });

  final bool isEditing;
  final DateTime date;
  final Color secondaryColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_calendar_rounded : Icons.add_alarm_rounded,
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
                isEditing ? 'Edit Time Block' : 'Add Missing Time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 17,
                  fontweight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: secondaryColor,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      MotionDateUtils.formatDisplayDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 10.5,
                        fontweight: FontWeight.normal,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: secondaryColor),
        ),
      ],
    );
  }
}

class _DailyDialogSectionLabel extends StatelessWidget {
  const _DailyDialogSectionLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColor.blueMainColor),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 11.5,
            fontweight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssignmentOption extends StatelessWidget {
  const _AssignmentOption({required this.assignment});

  final Assigner assignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;

    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: AppColor.blueMainColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            size: 17,
            color: AppColor.blueMainColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.subcategoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                assignment.mainCategoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 9.5,
                  fontweight: FontWeight.normal,
                  color: secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedActivity extends StatelessWidget {
  const _SelectedActivity({required this.entry});

  final Subcategories entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.blueMainColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            size: 18,
            color: AppColor.blueMainColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subcategoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12.5,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.mainCategoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 9.5,
                    fontweight: FontWeight.normal,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 9.5,
              fontweight: FontWeight.normal,
              color: secondary,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: border),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColor.blueMainColor,
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
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 21,
                fontweight: FontWeight.w800,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyle.subSectionTextStyle(
                  fontsize: 21,
                  fontweight: FontWeight.normal,
                  color: secondary.withValues(alpha: 0.55),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyDialogErrorMessage extends StatelessWidget {
  const _DailyDialogErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 17,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11,
                fontweight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
