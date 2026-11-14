import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';
import 'package:motion/motion_screens/ms_goals/goal_deadline_status.dart';
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
    final provider = context.read<GoalTrackerProvider>();
    final draft = await showGoalEditorDialog(
      context: context,
      goal: goal,
      collections: provider.collections,
    );
    if (draft == null || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().editGoal(
            goal: goal,
            name: draft.name,
            description: draft.description,
            startDate: draft.startDate,
            completionDate: draft.completionDate,
            deadlineDate: draft.deadlineDate,
            entryType: draft.entryType,
            collectionId: draft.collectionId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(goal.isGoal ? 'Goal updated.' : 'Timeline updated.'),
          ),
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
      title: goal.isGoal ? 'Delete Goal?' : 'Delete Timeline?',
      message: goal.isGoal
          ? 'This permanently removes ${goal.name} and its effort history.'
          : 'This permanently removes ${goal.name}.',
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
      title: goal.isGoal ? 'Mark as Achieved?' : 'Complete Timeline?',
      message: goal.isGoal
          ? 'Motion will stop the counter today and preserve the effort history for ${goal.name}.'
          : 'Motion will stop the counter today and preserve the full elapsed history for ${goal.name}.',
      actionLabel: goal.isGoal ? 'Achieved' : 'Complete',
      icon: goal.isGoal ? Icons.emoji_events_rounded : Icons.check_rounded,
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
          days: provider.activeDaysFor(updated),
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

  Future<void> _pause(MotionGoal goal) async {
    final draft = await showPauseGoalDialog(
      context: context,
      goalName: goal.name,
    );
    if (draft == null || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().pauseGoal(
            goal,
            reason: draft.reason,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    }
  }

  Future<void> _resumePaused(MotionGoal goal) async {
    final confirmed = await showGoalConfirmation(
      context: context,
      title: 'Resume Goal?',
      message:
          'The active-day counter will continue from where it stopped. Today becomes an active day again.',
      actionLabel: 'Resume',
      icon: Icons.play_arrow_rounded,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<GoalTrackerProvider>().resumePausedGoal(goal);
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
      title: goal.isGoal ? 'Reopen Goal?' : 'Resume Timeline?',
      message: goal.isGoal
          ? 'The counter will resume from the original start date. Existing effort history will remain.'
          : 'The counter will resume from the original start date.',
      actionLabel: goal.isGoal ? 'Reopen' : 'Resume',
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
            title: Text(goal?.name ?? 'Entry Details'),
            actions: goal == null
                ? null
                : [
                    PopupMenuButton<String>(
                      tooltip:
                          goal.isGoal ? 'Goal options' : 'Timeline options',
                      onSelected: (value) {
                        if (value == 'edit') _edit(goal);
                        if (value == 'delete') _delete(goal);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 19),
                              const SizedBox(width: 10),
                              Text(goal.isGoal ? 'Edit Goal' : 'Edit Timeline'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                goal.isGoal ? 'Delete Goal' : 'Delete Timeline',
                              ),
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
    final pausePeriods = provider.pausePeriodsFor(goal.id!);
    final isPaused = provider.isPaused(goal);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _GoalSummary(
          goal: goal,
          today: provider.today,
          collection: provider.collectionById(goal.collectionId),
          activeDays: provider.activeDaysFor(goal),
          pausedDays: provider.pausedDaysFor(goal),
          isPaused: isPaused,
        ),
        const SizedBox(height: 14),
        _GoalCalendar(
          goal: goal,
          visibleMonth: _visibleMonth!,
          today: provider.today,
          canGoBack: _visibleMonth!.isAfter(firstMonth),
          canGoForward: _visibleMonth!.isBefore(lastMonth),
          isCheckedIn: (date) => provider.isCheckedIn(goal.id!, date),
          isPausedDate: (date) => provider.isDatePaused(goal, date),
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
        if (goal.isGoal) ...[
          _CheckInHistory(checkIns: checkIns),
          if (pausePeriods.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PauseHistory(
              periods: pausePeriods,
              today: provider.today,
            ),
          ],
          const SizedBox(height: 18),
        ] else
          const SizedBox(height: 4),
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
            label: Text(goal.isGoal ? 'Reopen Goal' : 'Resume Timeline'),
          )
        else if (goal.isGoal)
          Column(
            children: [
              if (isPaused)
                FilledButton.icon(
                  onPressed:
                      provider.isSaving ? null : () => _resumePaused(goal),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColor.blueMainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume Goal'),
                )
              else
                OutlinedButton.icon(
                  onPressed: provider.isSaving ? null : () => _pause(goal),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.pause_rounded),
                  label: const Text('Pause Goal'),
                ),
              const SizedBox(height: 10),
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
            icon: Icon(
              goal.isGoal ? Icons.emoji_events_rounded : Icons.check_rounded,
            ),
            label: Text(
              goal.isGoal ? 'Mark as Achieved' : 'Complete Timeline',
            ),
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
              'Entry unavailable',
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
              label: const Text('Back to Timelines'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({
    required this.goal,
    required this.today,
    required this.collection,
    required this.activeDays,
    required this.pausedDays,
    required this.isPaused,
  });

  final MotionGoal goal;
  final DateTime today;
  final MotionTimelineCollection? collection;
  final int activeDays;
  final int pausedDays;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final elapsed = goal.elapsedDaysAt(today);
    final statusColor = goal.isAchieved
        ? Colors.green
        : isPaused
            ? Colors.orange
            : AppColor.blueMainColor;
    final deadlineStatus = deadlineStatusFor(goal, today);
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _DetailTag(
                          icon: goal.isGoal
                              ? Icons.flag_outlined
                              : Icons.timeline_rounded,
                          label: goal.isGoal ? 'Goal' : 'Timeline',
                          color: goal.isGoal
                              ? Colors.orange
                              : AppColor.blueMainColor,
                        ),
                        _DetailTag(
                          icon: collection == null
                              ? Icons.inbox_outlined
                              : Icons.folder_outlined,
                          label: collection?.name ?? 'Uncategorized',
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              MotionStatusPill(
                label: goal.isGoal
                    ? goal.isAchieved
                        ? 'Achieved'
                        : isPaused
                            ? 'Paused'
                            : 'Active'
                    : goal.isAchieved
                        ? 'Completed'
                        : 'Ongoing',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (goal.isGoal) ...[
            Row(
              children: [
                Expanded(
                  child: MotionMetric(
                    label: 'Active effort',
                    value: '$activeDays ${activeDays == 1 ? 'day' : 'days'}',
                  ),
                ),
                Expanded(
                  child: MotionMetric(
                    label: 'Calendar duration',
                    value: '$elapsed ${elapsed == 1 ? 'day' : 'days'}',
                    alignRight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: MotionMetric(
                    label: 'Started',
                    value: DateFormat('MMM d, yyyy').format(goal.startDate),
                  ),
                ),
                Expanded(
                  child: MotionMetric(
                    label: 'Paused',
                    value: '$pausedDays ${pausedDays == 1 ? 'day' : 'days'}',
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: MotionMetric(
                    label: goal.isAchieved ? 'Total duration' : 'Days elapsed',
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
          if (deadlineStatus != null) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: deadlineStatus.color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: deadlineStatus.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline ${DateFormat('MMM d, yyyy').format(deadlineStatus.deadline)}',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 10,
                            fontweight: FontWeight.w700,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deadlineStatus.label,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11.5,
                            fontweight: FontWeight.w900,
                            color: deadlineStatus.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _DetailTag extends StatelessWidget {
  const _DetailTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 9,
              fontweight: FontWeight.w800,
              color: color,
            ),
          ),
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
    required this.isPausedDate,
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
  final bool Function(DateTime date) isPausedDate;
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
                      goal.isTimeline
                          ? 'Every elapsed day is shown automatically'
                          : goal.isAchieved
                              ? 'Effort history'
                              : 'Tap a day you worked toward this goal',
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
              final paused = inRange && isPausedDate(date);
              final isElapsed = goal.isTimeline && inRange;
              final isToday = MotionDateUtils.isSameDate(date, today);
              final canTap =
                  goal.isGoal && inRange && !goal.isAchieved && !paused;
              final highlighted = checked || isElapsed;
              final textColor = paused
                  ? Colors.orange
                  : highlighted
                      ? Colors.white
                      : inRange
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Colors.blueGrey.withValues(alpha: 0.35);
              return Semantics(
                button: canTap,
                selected: highlighted,
                label: '${MotionDateUtils.formatDisplayDate(date)}'
                    '${checked ? ', worked toward goal' : ''}'
                    '${paused ? ', paused' : ''}'
                    '${isElapsed ? ', elapsed timeline day' : ''}',
                child: InkWell(
                  onTap: canTap ? () => onCheckIn(date) : null,
                  borderRadius: BorderRadius.circular(9),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: paused
                          ? Colors.orange.withValues(alpha: 0.12)
                          : highlighted
                              ? AppColor.blueMainColor
                              : neutral,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isToday ? Colors.orange : Colors.transparent,
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
                        if (checked && goal.isGoal)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        if (paused)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: Icon(
                              Icons.pause_rounded,
                              color: Colors.orange,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalendarLegend(
                color: AppColor.blueMainColor,
                label: goal.isGoal ? 'Worked' : 'Elapsed',
              ),
              const SizedBox(width: 16),
              const _CalendarLegend(
                color: Colors.orange,
                label: 'Today',
                outlined: true,
              ),
              if (goal.isGoal) ...[
                const SizedBox(width: 16),
                const _CalendarLegend(
                  color: Colors.orange,
                  label: 'Paused',
                ),
              ],
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
                  'Effort History',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w900,
                  ),
                ),
              ),
              MotionStatusPill(
                label:
                    '${checkIns.length} ${checkIns.length == 1 ? 'day' : 'days'}',
                color: AppColor.blueMainColor,
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (recent.isEmpty)
            Text(
              'No effort days have been marked yet.',
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
              '${checkIns.length - recent.length} older effort days remain visible in the calendar.',
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

class _PauseHistory extends StatelessWidget {
  const _PauseHistory({required this.periods, required this.today});

  final List<GoalPausePeriod> periods;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return MotionPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pause_circle_outline_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pause History',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 14,
                    fontweight: FontWeight.w900,
                  ),
                ),
              ),
              MotionStatusPill(
                label: '${periods.length}',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...periods.map((period) {
            final end = period.resumeDate ?? today;
            final days = end.isAfter(period.startDate)
                ? end.difference(period.startDate).inDays
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.pause_rounded,
                      color: Colors.orange,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.isOpen
                                ? 'Paused since ${MotionDateUtils.formatDisplayDate(period.startDate)}'
                                : '${MotionDateUtils.formatDisplayDate(period.startDate)} - ${MotionDateUtils.formatDisplayDate(period.resumeDate!)}',
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 10.5,
                              fontweight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${period.isOpen ? 'Currently paused' : '$days ${days == 1 ? 'day' : 'days'}'}'
                            '${period.reason.isEmpty ? '' : '  •  ${period.reason}'}',
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 9.5,
                              fontweight: FontWeight.normal,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
