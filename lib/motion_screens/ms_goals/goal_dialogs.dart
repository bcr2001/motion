import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_date_picker_dialog.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';

class GoalDraft {
  const GoalDraft({
    required this.name,
    required this.description,
    required this.startDate,
  });

  final String name;
  final String description;
  final DateTime startDate;
}

Future<GoalDraft?> showGoalEditorDialog({
  required BuildContext context,
  MotionGoal? goal,
}) {
  return showDialog<GoalDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GoalEditorDialog(goal: goal),
  );
}

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({this.goal});

  final MotionGoal? goal;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime _startDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _startDate = widget.goal?.startDate ?? MotionDateUtils.today();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showMotionDatePickerDialog(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: MotionDateUtils.today(),
      title: 'Goal Start Date',
      confirmLabel: 'Use Date',
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for your goal.');
      return;
    }
    final completionDate = widget.goal?.completionDate;
    if (completionDate != null && _startDate.isAfter(completionDate)) {
      setState(() => _error = 'Start date cannot be after completion.');
      return;
    }
    Navigator.of(context).pop(GoalDraft(
      name: name,
      description: _descriptionController.text.trim(),
      startDate: _startDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;
    final inputFill = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : Colors.white.withValues(alpha: 0.75);
    final inputDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColor.blueMainColor, width: 1.4),
      ),
    );

    return Dialog(
      backgroundColor: panelColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: AppColor.blueMainColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: AppColor.blueMainColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.goal == null ? 'Create Goal' : 'Edit Goal',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 16,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: secondary),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Goal name',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: widget.goal == null,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColor.blueMainColor,
                maxLength: 80,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12.5,
                  fontweight: FontWeight.w700,
                ),
                decoration: inputDecoration.copyWith(
                  counterText: '',
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    'Notes',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.w800,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'optional',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 9.5,
                      fontweight: FontWeight.normal,
                      color: secondary.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColor.blueMainColor,
                maxLines: 2,
                maxLength: 300,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                ),
                decoration: inputDecoration.copyWith(
                  hintText: 'Why this goal matters to you',
                  hintStyle: AppTextStyle.subSectionTextStyle(
                    fontsize: 10,
                    fontweight: FontWeight.normal,
                    color: secondary.withValues(alpha: 0.42),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Starting date',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColor.blueMainColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          MotionDateUtils.formatDisplayDate(_startDate),
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11.5,
                            fontweight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: secondary),
                    ],
                  ),
                ),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: secondary,
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: AppColor.blueMainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(widget.goal == null ? 'Create Goal' : 'Save'),
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

Future<bool> showGoalConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
  required IconData icon,
  Color actionColor = AppColor.blueMainColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final panelColor = isDark
          ? AppColor.darkModeContentWidget
          : AppColor.lightModeContentWidget;
      final secondary = isDark ? Colors.white60 : Colors.blueGrey;
      final border = isDark ? Colors.white12 : Colors.black12;
      return AlertDialog(
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: actionColor, size: 21),
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
          ],
        ),
        content: Text(
          message,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 12.5,
            fontweight: FontWeight.normal,
            color: secondary,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondary,
                      side: BorderSide(color: border),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<void> showGoalAchievedDialog({
  required BuildContext context,
  required MotionGoal goal,
  required int days,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark
            ? AppColor.darkModeContentWidget
            : AppColor.lightModeContentWidget,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Goal Achieved',
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 21).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${goal.name} took $days ${days == 1 ? 'day' : 'days'}.',
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 12.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
