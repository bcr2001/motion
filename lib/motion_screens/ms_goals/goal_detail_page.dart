import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class GoalDetailPage extends StatefulWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final int goalId;

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  DateTime? _visibleMonth;

  String _message(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(State|Argument)Error: '), '');
  }

  Future<void> _edit(MotionGoal goal) async {
    final draft = await showGoalEditorDialog(context: context, goal: goal);
    if (draft == null || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().editGoal(
            goal: goal,
            name: draft.name,
            description: draft.description,
            startDate: draft.startDate,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    }
  }

  Future<void> _delete(MotionGoal goal) async {
    final confirmed = await showGoalConfirmation(
      context: context,
      title: 'Delete Goal?',
      message:
          'This permanently removes ${goal.name} and its check-in history.',
      actionLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      actionColor: Colors.redAccent,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().deleteGoal(goal);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    }
  }

  Future<void> _achieve(MotionGoal goal) async {
    final confirmed = await showGoalConfirmation(
      context: context,
      title: 'Mark as Achieved?',
      message:
          'Motion will stop the counter today and preserve every check-in for ${goal.name}.',
      actionLabel: 'Achieved',
      icon: Icons.emoji_events_rounded,
      actionColor: Colors.green,
    );
    if (!confirmed || !mounted) return;
    try {
      final provider = context.read<GoalTrackerProvider>();
      await provider.markAchieved(goal);
      if (!mounted) return;
      final updated = provider.goalById(goal.id!);
      if (updated != null) {
        await showGoalAchievedDialog(
          context: context,
          goal: updated,
          days: updated.elapsedDaysAt(provider.today),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    }
  }

  Future<void> _reopen(MotionGoal goal) async {
    final confirmed = await showGoalConfirmation(
      context: context,
      title: 'Reopen Goal?',
      message:
          'The counter will resume from the original start date. Existing check-ins will remain.',
      actionLabel: 'Reopen',
      icon: Icons.replay_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().reopenGoal(goal);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalTrackerProvider>(
      builder: (context, provider, _) {
        final goal = provider.goalById(widget.goalId);
        return Scaffold(
          appBar: AppBar(
            title: Text(goal?.name ?? 'Goal Details'),
            actions: goal == null
                ? null
                : [
                    PopupMenuButton<String>(
                      tooltip: 'Goal options',
                      onSelected: (value) {
                        if (value == 'edit') _edit(goal);
                        if (value == 'delete') _delete(goal);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 19),
                              SizedBox(width: 10),
                              Text('Edit Goal'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 10),
                              Text('Delete Goal'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
          body: goal == null
              ? provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _GoalUnavailable(onBack: () => Navigator.maybePop(context))
              : _buildBody(context, provider, goal),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    GoalTrackerProvider provider,
    MotionGoal goal,
  ) {
    final endDate = goal.completionDate ?? provider.today;
    final firstMonth = DateTime(goal.startDate.year, goal.startDate.month);
    final lastMonth = DateTime(endDate.year, endDate.month);
    _visibleMonth ??= lastMonth;
    if (_visibleMonth!.isBefore(firstMonth)) _visibleMonth = firstMonth;
    if (_visibleMonth!.isAfter(lastMonth)) _visibleMonth = lastMonth;
    final checkIns = provider.checkInsFor(goal.id!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _GoalSummary(goal: goal, today: provider.today),
        const SizedBox(height: 14),
        _GoalCalendar(
          goal: goal,
          visibleMonth: _visibleMonth!,
          today: provider.today,
          canGoBack: _visibleMonth!.isAfter(firstMonth),
          canGoForward: _visibleMonth!.isBefore(lastMonth),
          isCheckedIn: (date) => provider.isCheckedIn(goal.id!, date),
          onPreviousMonth: () => setState(() {
            _visibleMonth =
                DateTime(_visibleMonth!.year, _visibleMonth!.month - 1);
          }),
          onNextMonth: () => setState(() {
            _visibleMonth =
                DateTime(_visibleMonth!.year, _visibleMonth!.month + 1);
          }),
          onCheckIn: (date) async {
            try {
              await provider.toggleCheckIn(goal, date);
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_message(error))),
                );
              }
            }
          },
        ),
        const SizedBox(height: 14),
        _CheckInHistory(checkIns: checkIns),
        const SizedBox(height: 18),
        if (goal.isAchieved)
          OutlinedButton.icon(
            onPressed: provider.isSaving ? null : () => _reopen(goal),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: AppColor.blueMainColor,
              side: const BorderSide(color: AppColor.blueMainColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Reopen Goal'),
          )
        else
          FilledButton.icon(
            onPressed: provider.isSaving ? null : () => _achieve(goal),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.emoji_events_rounded),
            label: const Text('Mark as Achieved'),
          ),
      ],
    );
  }
}

class _GoalUnavailable extends StatelessWidget {
  const _GoalUnavailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 42,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 12),
            Text(
              'Goal unavailable',
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 17,
                fontweight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'It may have been deleted or belong to another Motion account.',
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11.5,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to Goals'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goal, required this.today});

  final MotionGoal goal;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final elapsed = goal.elapsedDaysAt(today);
    final statusColor = goal.isAchieved ? Colors.green : AppColor.blueMainColor;
    return MotionPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTextStyle.sectionTitleTextStyle(fontsize: 21)
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        goal.description,
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
              const SizedBox(width: 10),
              MotionStatusPill(
                label: goal.isAchieved ? 'Achieved' : 'Active',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MotionMetric(
                  label: goal.isAchieved ? 'Time taken' : 'Days elapsed',
                  value: '$elapsed ${elapsed == 1 ? 'day' : 'days'}',
                ),
              ),
              Expanded(
                child: MotionMetric(
                  label: 'Started',
                  value: DateFormat('MMM d, yyyy').format(goal.startDate),
                  alignRight: true,
                ),
              ),
            ],
          ),
          if (goal.completionDate != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completed ${MotionDateUtils.formatDisplayDate(goal.completionDate!)}',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 11.5,
                        fontweight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCalendar extends StatelessWidget {
  const _GoalCalendar({
    required this.goal,
    required this.visibleMonth,
    required this.today,
    required this.canGoBack,
    required this.canGoForward,
    required this.isCheckedIn,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onCheckIn,
  });

  final MotionGoal goal;
  final DateTime visibleMonth;
  final DateTime today;
  final bool canGoBack;
  final bool canGoForward;
  final bool Function(DateTime date) isCheckedIn;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onCheckIn;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final dayCount = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final cellCount = ((leading + dayCount) / 7).ceil() * 7;
    final endDate = goal.completionDate ?? today;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutral = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : Colors.black.withValues(alpha: 0.035);

    return MotionPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: canGoBack ? onPreviousMonth : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(visibleMonth),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 14,
                        fontweight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.isAchieved
                          ? 'Check-in history'
                          : 'Tap a day to mark still working',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 9.5,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: canGoForward ? onNextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = index - leading + 1;
              if (day < 1 || day > dayCount) return const SizedBox.shrink();
              final date = DateTime(visibleMonth.year, visibleMonth.month, day);
              final inRange =
                  !date.isBefore(goal.startDate) && !date.isAfter(endDate);
              final checked = inRange && isCheckedIn(date);
              final isToday = MotionDateUtils.isSameDate(date, today);
              final canTap = inRange && !goal.isAchieved;
              final textColor = checked
                  ? Colors.white
                  : inRange
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : Colors.blueGrey.withValues(alpha: 0.35);
              return Semantics(
                button: canTap,
                selected: checked,
                label:
                    '${MotionDateUtils.formatDisplayDate(date)}${checked ? ', checked in' : ''}',
                child: InkWell(
                  onTap: canTap ? () => onCheckIn(date) : null,
                  borderRadius: BorderRadius.circular(9),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: checked ? AppColor.blueMainColor : neutral,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isToday
                            ? AppColor.blueMainColor
                            : Colors.transparent,
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11,
                            fontweight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (checked)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalendarLegend(color: AppColor.blueMainColor, label: 'Checked'),
              SizedBox(width: 16),
              _CalendarLegend(
                color: AppColor.blueMainColor,
                label: 'Today',
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyle.subSectionTextStyle(
          fontsize: 9.5,
          fontweight: FontWeight.w800,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 9.5,
            fontweight: FontWeight.normal,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

class _CheckInHistory extends StatelessWidget {
  const _CheckInHistory({required this.checkIns});

  final List<GoalCheckIn> checkIns;

  @override
  Widget build(BuildContext context) {
    final recent = checkIns.take(8).toList(growable: false);
    return MotionPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColor.blueMainColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check-In History',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w900,
                  ),
                ),
              ),
              MotionStatusPill(
                label: '${checkIns.length} marked',
                color: AppColor.blueMainColor,
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (recent.isEmpty)
            Text(
              'No days have been checked yet.',
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: recent
                  .map(
                    (checkIn) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.blueMainColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(checkIn.date),
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 10,
                          fontweight: FontWeight.w700,
                          color: AppColor.blueMainColor,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (checkIns.length > recent.length) ...[
            const SizedBox(height: 9),
            Text(
              '${checkIns.length - recent.length} older check-ins remain visible in the calendar.',
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
