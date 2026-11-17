import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.completionDate,
    required this.deadlineDate,
    required this.targetDays,
    required this.entryType,
    this.collectionId,
    this.prerequisiteId,
    this.startsAutomaticallyAfterPrerequisites = false,
  });

  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? completionDate;
  final DateTime? deadlineDate;
  final int? targetDays;
  final TimelineEntryType entryType;
  final int? collectionId;
  final int? prerequisiteId;
  final bool startsAutomaticallyAfterPrerequisites;
}

Future<GoalDraft?> showGoalEditorDialog({
  required BuildContext context,
  MotionGoal? goal,
  required List<MotionTimelineCollection> collections,
  required List<MotionGoal> goals,
  int? initialCollectionId,
  int? initialPrerequisiteId,
  Set<int> invalidPrerequisiteIds = const {},
  bool prerequisiteEditable = true,
}) {
  return showDialog<GoalDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GoalEditorDialog(
      goal: goal,
      collections: collections,
      goals: goals,
      initialCollectionId: initialCollectionId,
      initialPrerequisiteId: initialPrerequisiteId,
      invalidPrerequisiteIds: invalidPrerequisiteIds,
      prerequisiteEditable: prerequisiteEditable,
    ),
  );
}

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({
    this.goal,
    required this.collections,
    required this.goals,
    this.initialCollectionId,
    this.initialPrerequisiteId,
    required this.invalidPrerequisiteIds,
    required this.prerequisiteEditable,
  });

  final MotionGoal? goal;
  final List<MotionTimelineCollection> collections;
  final List<MotionGoal> goals;
  final int? initialCollectionId;
  final int? initialPrerequisiteId;
  final Set<int> invalidPrerequisiteIds;
  final bool prerequisiteEditable;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetDaysController;
  late DateTime _startDate;
  DateTime? _completionDate;
  DateTime? _deadlineDate;
  late TimelineEntryType _entryType;
  late int _collectionKey;
  late int _prerequisiteKey;
  late bool _startsAutomaticallyAfterPrerequisites;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _targetDaysController = TextEditingController(
      text: widget.goal?.targetDays?.toString() ?? '',
    );
    _startDate = widget.goal?.startDate ?? MotionDateUtils.today();
    _completionDate = widget.goal?.completionDate;
    _deadlineDate = widget.goal?.deadlineDate;
    _entryType = widget.goal?.entryType ?? TimelineEntryType.timeline;
    _collectionKey =
        widget.goal?.collectionId ?? widget.initialCollectionId ?? -1;
    _prerequisiteKey = widget.initialPrerequisiteId ?? -1;
    _startsAutomaticallyAfterPrerequisites =
        widget.goal?.startsAutomaticallyAfterPrerequisites ??
            widget.initialPrerequisiteId != null;
  }

  MotionGoal? get _selectedPrerequisite {
    for (final goal in widget.goals) {
      if (goal.id == _prerequisiteKey) return goal;
    }
    return null;
  }

  bool get _isWaitingForPrerequisite {
    final prerequisite = _selectedPrerequisite;
    return prerequisite != null &&
        !prerequisite.isAchieved &&
        widget.goal?.activationDate == null;
  }

  DateTime get _effectiveStartBoundary {
    final existingActivation = widget.goal?.activationDate;
    if (_prerequisiteKey != -1 && existingActivation != null) {
      return existingActivation;
    }
    final prerequisite = _selectedPrerequisite;
    if (_startsAutomaticallyAfterPrerequisites &&
        prerequisite?.completionDate != null) {
      return prerequisite!.completionDate!;
    }
    return _startDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = MotionDateUtils.today();
    final picked = await showMotionDatePickerDialog(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year + 100, 12, 31),
      title: 'Timeline Start Date',
      confirmLabel: 'Use Date',
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(today)) _completionDate = null;
        if (_deadlineDate != null && _deadlineDate!.isBefore(_startDate)) {
          _deadlineDate = null;
        }
        _error = null;
      });
    }
  }

  Future<void> _selectCompletionDate() async {
    if (widget.goal?.isFailed == true ||
        _isWaitingForPrerequisite ||
        _effectiveStartBoundary.isAfter(MotionDateUtils.today())) {
      return;
    }
    final initialDate = _completionDate == null ||
            _completionDate!.isBefore(_effectiveStartBoundary)
        ? _effectiveStartBoundary
        : _completionDate!;
    final picked = await showMotionDatePickerDialog(
      context: context,
      initialDate: initialDate,
      firstDate: _effectiveStartBoundary,
      lastDate: MotionDateUtils.today(),
      title: 'Timeline Ending Date',
      confirmLabel: 'Use Date',
    );
    if (picked != null && mounted) {
      setState(() {
        _completionDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _selectDeadlineDate() async {
    final today = MotionDateUtils.today();
    final preferredDate = _deadlineDate ?? _completionDate ?? today;
    final boundary = _effectiveStartBoundary;
    final initialDate =
        preferredDate.isBefore(boundary) ? boundary : preferredDate;
    final picked = await showMotionDatePickerDialog(
      context: context,
      initialDate: initialDate,
      firstDate: boundary,
      lastDate: DateTime(today.year + 100, 12, 31),
      title: 'Goal Deadline',
      confirmLabel: 'Use Date',
    );
    if (picked != null && mounted) {
      setState(() {
        _deadlineDate = picked;
        _error = null;
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter what you are tracking.');
      return;
    }
    if (_completionDate != null && _isWaitingForPrerequisite) {
      setState(() =>
          _error = 'Complete the prerequisite before adding an ending date.');
      return;
    }
    if (_completionDate != null &&
        _effectiveStartBoundary.isAfter(_completionDate!)) {
      setState(() => _error = 'Ending date cannot be before the start date.');
      return;
    }
    if (_entryType == TimelineEntryType.goal &&
        _deadlineDate != null &&
        _effectiveStartBoundary.isAfter(_deadlineDate!)) {
      setState(() => _error = 'Deadline cannot be before the start date.');
      return;
    }
    final targetDaysText = _targetDaysController.text.trim();
    final targetDays =
        targetDaysText.isEmpty ? null : int.tryParse(targetDaysText);
    if (targetDaysText.isNotEmpty && (targetDays == null || targetDays <= 0)) {
      setState(() => _error = 'Required duration must be at least one day.');
      return;
    }
    Navigator.of(context).pop(GoalDraft(
      name: name,
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      completionDate: _completionDate,
      deadlineDate: _entryType == TimelineEntryType.goal ? _deadlineDate : null,
      targetDays: _entryType == TimelineEntryType.goal ? targetDays : null,
      entryType: _entryType,
      collectionId: _collectionKey == -1 ? null : _collectionKey,
      prerequisiteId: _prerequisiteKey == -1 ? null : _prerequisiteKey,
      startsAutomaticallyAfterPrerequisites:
          _prerequisiteKey != -1 && _startsAutomaticallyAfterPrerequisites,
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
    final isUpcoming = !_isWaitingForPrerequisite &&
        _effectiveStartBoundary.isAfter(MotionDateUtils.today());
    final isEndingDateUnavailable = isUpcoming ||
        _isWaitingForPrerequisite ||
        widget.goal?.isFailed == true;

    return Dialog(
      backgroundColor: panelColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 650),
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
                    child: Icon(
                      _entryType == TimelineEntryType.goal
                          ? Icons.flag_outlined
                          : Icons.timeline_rounded,
                      color: AppColor.blueMainColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.goal == null
                          ? _entryType == TimelineEntryType.goal
                              ? 'New Goal'
                              : 'New Timeline'
                          : _entryType == TimelineEntryType.goal
                              ? 'Edit Goal'
                              : 'Edit Timeline',
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
              _EntryTypeSelector(
                selected: _entryType,
                onSelected: (value) => setState(() => _entryType = value),
              ),
              const SizedBox(height: 15),
              Text(
                _entryType == TimelineEntryType.goal
                    ? 'What do you want to achieve?'
                    : 'What are you tracking?',
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
                  hintText: _entryType == TimelineEntryType.goal
                      ? 'Add a note about this goal'
                      : 'Add a note about this timeline',
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
                'Collection',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _collectionKey,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: inputDecoration,
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Uncategorized'),
                  ),
                  ...widget.collections.map(
                    (collection) => DropdownMenuItem<int>(
                      value: collection.id,
                      child: Text(
                        collection.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: widget.prerequisiteEditable || _prerequisiteKey == -1
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _collectionKey = value;
                            final prerequisite = widget.goals.where(
                              (goal) => goal.id == _prerequisiteKey,
                            );
                            if (prerequisite.isEmpty ||
                                prerequisite.first.collectionId !=
                                    (_collectionKey == -1
                                        ? null
                                        : _collectionKey)) {
                              _prerequisiteKey = -1;
                              _startsAutomaticallyAfterPrerequisites = false;
                            }
                            _error = null;
                          });
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 13),
              Text(
                'Starts after',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                key: const Key('goalPrerequisiteField'),
                initialValue: _prerequisiteKey,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: inputDecoration,
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('No prerequisite'),
                  ),
                  ...widget.goals
                      .where(
                        (goal) =>
                            goal.id != null &&
                            _collectionKey != -1 &&
                            goal.collectionId == _collectionKey &&
                            !widget.invalidPrerequisiteIds.contains(goal.id),
                      )
                      .map(
                        (goal) => DropdownMenuItem<int>(
                          value: goal.id,
                          child: Row(
                            children: [
                              Icon(
                                goal.isAchieved
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_clock_rounded,
                                size: 16,
                                color: goal.isAchieved
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                onChanged: widget.prerequisiteEditable && _collectionKey != -1
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            final changed = value != _prerequisiteKey;
                            _prerequisiteKey = value;
                            _startsAutomaticallyAfterPrerequisites =
                                value != -1;
                            if (changed && value != -1) {
                              final prerequisite = _selectedPrerequisite;
                              _startDate = prerequisite?.completionDate ??
                                  MotionDateUtils.today();
                              if (prerequisite?.isAchieved != true) {
                                _completionDate = null;
                              }
                            }
                            _error = null;
                          });
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                _collectionKey == -1
                    ? 'Choose a collection before linking a progression.'
                    : _prerequisiteKey == -1
                        ? 'Optional. Link this entry to the step that must be completed first.'
                        : widget.prerequisiteEditable
                            ? _startsAutomaticallyAfterPrerequisites
                                ? 'This entry starts automatically when the selected item is completed.'
                                : 'This entry waits for the prerequisite and the delayed start date.'
                            : 'Progression links cannot change after an entry starts.',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 9.5,
                  fontweight: FontWeight.normal,
                  color: secondary.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 13),
              if (_prerequisiteKey == -1) ...[
                _DateFieldLabel(label: 'Starting date', color: secondary),
                const SizedBox(height: 6),
                _GoalDateField(
                  fieldKey: const Key('timelineStartingDateField'),
                  value: _startDate,
                  onTap: _selectDate,
                  fillColor: inputFill,
                  borderColor: border,
                  secondaryColor: secondary,
                ),
              ] else ...[
                Container(
                  key: const Key('automaticPrerequisiteStartPanel'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.blueMainColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColor.blueMainColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColor.blueMainColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _startsAutomaticallyAfterPrerequisites
                                  ? 'Starts automatically'
                                  : 'Delayed start',
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 11.5,
                                fontweight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _startsAutomaticallyAfterPrerequisites
                                  ? 'Begins when ${_selectedPrerequisite?.name ?? 'the prerequisite'} is completed.'
                                  : 'Begins after the prerequisite is completed and the selected date arrives.',
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
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  key: const Key('delayPrerequisiteStartSwitch'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  title: Text(
                    'Delay start until a specific date',
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.w800,
                    ),
                  ),
                  value: !_startsAutomaticallyAfterPrerequisites,
                  onChanged: widget.prerequisiteEditable
                      ? (delayStart) {
                          setState(() {
                            _startsAutomaticallyAfterPrerequisites =
                                !delayStart;
                            if (!delayStart &&
                                _selectedPrerequisite?.completionDate != null) {
                              _startDate =
                                  _selectedPrerequisite!.completionDate!;
                            }
                            _error = null;
                          });
                        }
                      : null,
                ),
                if (!_startsAutomaticallyAfterPrerequisites) ...[
                  const SizedBox(height: 5),
                  _DateFieldLabel(label: 'Not before', color: secondary),
                  const SizedBox(height: 6),
                  _GoalDateField(
                    fieldKey: const Key('delayedPrerequisiteStartDateField'),
                    value: _startDate,
                    onTap: _selectDate,
                    fillColor: inputFill,
                    borderColor: border,
                    secondaryColor: secondary,
                  ),
                ],
              ],
              if (_entryType == TimelineEntryType.goal) ...[
                const SizedBox(height: 13),
                Row(
                  children: [
                    Text(
                      'Required duration',
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
                  key: const Key('goalTargetDaysField'),
                  controller: _targetDaysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: AppColor.blueMainColor,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12,
                    fontweight: FontWeight.w700,
                  ),
                  decoration: inputDecoration.copyWith(
                    hintText: 'e.g. 7',
                    hintStyle: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                      color: secondary.withValues(alpha: 0.50),
                    ),
                    suffixText: 'days',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Achievement stays locked until this many active days have elapsed.',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 9.5,
                    fontweight: FontWeight.normal,
                    color: secondary.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Text(
                      'Deadline',
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
                InkWell(
                  key: const Key('goalDeadlineDateField'),
                  onTap: _selectDeadlineDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    constraints: const BoxConstraints(minHeight: 42),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _deadlineDate == null
                              ? Icons.event_outlined
                              : Icons.event_rounded,
                          color:
                              _deadlineDate == null ? secondary : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _deadlineDate == null
                                ? 'No deadline'
                                : MotionDateUtils.formatDisplayDate(
                                    _deadlineDate!,
                                  ),
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 11.5,
                              fontweight: FontWeight.w800,
                              color: _deadlineDate == null ? secondary : null,
                            ),
                          ),
                        ),
                        if (_deadlineDate != null)
                          IconButton(
                            key: const Key('clearGoalDeadlineDate'),
                            tooltip: 'Remove deadline',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              _deadlineDate = null;
                              _error = null;
                            }),
                            icon: Icon(Icons.close_rounded, color: secondary),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    'Ending date',
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
              InkWell(
                key: const Key('timelineEndingDateField'),
                onTap: isEndingDateUnavailable ? null : _selectCompletionDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  constraints: const BoxConstraints(minHeight: 42),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEndingDateUnavailable
                            ? Icons.schedule_rounded
                            : _completionDate == null
                                ? Icons.all_inclusive_rounded
                                : Icons.event_available_rounded,
                        color:
                            isEndingDateUnavailable || _completionDate == null
                                ? secondary
                                : AppColor.blueMainColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isWaitingForPrerequisite
                              ? 'Available after the prerequisite is completed'
                              : isUpcoming
                                  ? 'Available after the start date'
                                  : _completionDate == null
                                      ? 'Ongoing'
                                      : MotionDateUtils.formatDisplayDate(
                                          _completionDate!,
                                        ),
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11.5,
                            fontweight: FontWeight.w800,
                            color: isEndingDateUnavailable ||
                                    _completionDate == null
                                ? secondary
                                : null,
                          ),
                        ),
                      ),
                      if (!isEndingDateUnavailable && _completionDate != null)
                        IconButton(
                          key: const Key('clearTimelineEndingDate'),
                          tooltip: 'Keep ongoing',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _completionDate = null;
                            _error = null;
                          }),
                          icon: Icon(Icons.close_rounded, color: secondary),
                        )
                      else if (!isEndingDateUnavailable)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: secondary,
                          ),
                        ),
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
                      label: Text(
                        widget.goal == null
                            ? _entryType == TimelineEntryType.goal
                                ? 'Create Goal'
                                : _isWaitingForPrerequisite
                                    ? 'Create Timeline'
                                    : isUpcoming
                                        ? 'Schedule Timeline'
                                        : _completionDate == null
                                            ? 'Start Timeline'
                                            : 'Add Timeline'
                            : 'Save',
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
}

class _DateFieldLabel extends StatelessWidget {
  const _DateFieldLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyle.subSectionTextStyle(
        fontsize: 10.5,
        fontweight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _GoalDateField extends StatelessWidget {
  const _GoalDateField({
    required this.fieldKey,
    required this.value,
    required this.onTap,
    required this.fillColor,
    required this.borderColor,
    required this.secondaryColor,
  });

  final Key fieldKey;
  final DateTime value;
  final VoidCallback onTap;
  final Color fillColor;
  final Color borderColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
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
                MotionDateUtils.formatDisplayDate(value),
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: secondaryColor),
          ],
        ),
      ),
    );
  }
}

class _EntryTypeSelector extends StatelessWidget {
  const _EntryTypeSelector({
    required this.selected,
    required this.onSelected,
  });

  final TimelineEntryType selected;
  final ValueChanged<TimelineEntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: TimelineEntryType.values.map((type) {
          final isSelected = selected == type;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(type),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == TimelineEntryType.goal
                          ? Icons.flag_outlined
                          : Icons.timeline_rounded,
                      size: 17,
                      color:
                          isSelected ? AppColor.blueMainColor : Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type == TimelineEntryType.goal ? 'Goal' : 'Timeline',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 11,
                        fontweight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? AppColor.blueMainColor
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

Future<String?> showCollectionNameDialog({
  required BuildContext context,
  MotionTimelineCollection? collection,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CollectionNameDialog(collection: collection),
  );
}

class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({this.collection});

  final MotionTimelineCollection? collection;

  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.collection?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a collection name.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final boundary = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.10);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.025);

    return Dialog(
      backgroundColor: isDark
          ? AppColor.darkModeContentWidget
          : AppColor.lightModeContentWidget,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: boundary),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, minHeight: 310),
        child: SizedBox(
          key: const Key('collectionNameDialogSurface'),
          width: double.maxFinite,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.create_new_folder_outlined,
                        color: AppColor.blueMainColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        widget.collection == null
                            ? 'New Collection'
                            : 'Rename Collection',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 18,
                          fontweight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  'Use collections to keep related timelines and goals together.',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11.5,
                    fontweight: FontWeight.normal,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 21),
                Text(
                  'Collection name',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColor.blueMainColor,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 13,
                    fontweight: FontWeight.w700,
                    color: primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Calisthenics',
                    hintStyle: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.normal,
                      color: secondary.withValues(alpha: 0.65),
                    ),
                    counterText: '',
                    errorText: _error,
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: boundary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: AppColor.blueMainColor,
                        width: 1.4,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondary,
                          side: BorderSide(color: boundary),
                          minimumSize: const Size(0, 47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColor.blueMainColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.collection == null ? 'Create' : 'Save',
                        ),
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
  }
}

class GoalPauseDraft {
  const GoalPauseDraft({required this.reason});

  final String reason;
}

Future<GoalPauseDraft?> showPauseGoalDialog({
  required BuildContext context,
  required String goalName,
}) {
  return showDialog<GoalPauseDraft>(
    context: context,
    builder: (_) => _PauseGoalDialog(goalName: goalName),
  );
}

class _PauseGoalDialog extends StatefulWidget {
  const _PauseGoalDialog({required this.goalName});

  final String goalName;

  @override
  State<_PauseGoalDialog> createState() => _PauseGoalDialogState();
}

class _PauseGoalDialogState extends State<_PauseGoalDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final primary = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;
    return Dialog(
      backgroundColor: panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Pause Goal?',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 17,
                        fontweight: FontWeight.w900,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${widget.goalName} will keep its existing active days. The counter continues when you resume.',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.normal,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Reason (optional)',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLength: 200,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColor.blueMainColor,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: primary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Recovering from an injury',
                  hintStyle: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: secondary.withValues(alpha: 0.55),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.black.withValues(alpha: 0.025),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColor.blueMainColor,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: secondary,
                        side: BorderSide(color: border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        GoalPauseDraft(reason: _reasonController.text.trim()),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.pause_rounded, size: 18),
                      label: const Text('Pause'),
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

class GoalFailureDraft {
  const GoalFailureDraft({required this.reason});

  final String reason;
}

Future<GoalFailureDraft?> showFailGoalDialog({
  required BuildContext context,
  required String goalName,
}) {
  return showDialog<GoalFailureDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FailGoalDialog(goalName: goalName),
  );
}

class _FailGoalDialog extends StatefulWidget {
  const _FailGoalDialog({required this.goalName});

  final String goalName;

  @override
  State<_FailGoalDialog> createState() => _FailGoalDialogState();
}

class _FailGoalDialogState extends State<_FailGoalDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final primary = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.white60 : Colors.blueGrey;
    final border = isDark ? Colors.white12 : Colors.black12;
    return Dialog(
      backgroundColor: panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'End as Failed?',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 17,
                        fontweight: FontWeight.w900,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${widget.goalName} will stop today. Its history will remain available and it will not unlock dependent entries.',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.normal,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'What happened? (optional)',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('goalFailureReasonField'),
                controller: _reasonController,
                maxLength: 200,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: Colors.redAccent,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12,
                  fontweight: FontWeight.normal,
                  color: primary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a short note for this attempt',
                  hintStyle: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: secondary.withValues(alpha: 0.55),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.black.withValues(alpha: 0.025),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: secondary,
                        side: BorderSide(color: border),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('confirmGoalFailureButton'),
                      onPressed: () => Navigator.pop(
                        context,
                        GoalFailureDraft(
                          reason: _reasonController.text.trim(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('End Attempt'),
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
              child: Icon(
                goal.isGoal
                    ? Icons.emoji_events_rounded
                    : Icons.check_circle_rounded,
                color: Colors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              goal.isGoal ? 'Goal Achieved' : 'Timeline Complete',
              style: AppTextStyle.sectionTitleTextStyle(fontsize: 21).copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              goal.isGoal
                  ? '${goal.name} took $days ${days == 1 ? 'day' : 'days'} to achieve.'
                  : '${goal.name} lasted $days ${days == 1 ? 'day' : 'days'}.',
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
