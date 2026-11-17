import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_reusable/motion_ui/motion_snack_bar.dart';
import 'package:motion/motion_screens/ms_goals/goal_detail_page.dart';
import 'package:motion/motion_screens/ms_goals/goal_deadline_status.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';
import 'package:motion/motion_screens/ms_goals/timeline_collections_page.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class GoalTrackerPage extends StatelessWidget {
  const GoalTrackerPage({super.key});

  Future<void> _createGoal(BuildContext context) async {
    final provider = context.read<GoalTrackerProvider>();
    final draft = await showGoalEditorDialog(
      context: context,
      collections: provider.collections,
      goals: provider.goals,
      initialCollectionId:
          provider.showAllCollections ? null : provider.selectedCollectionId,
    );
    if (draft == null || !context.mounted) return;
    try {
      final goal = await context.read<GoalTrackerProvider>().createGoal(
            name: draft.name,
            description: draft.description,
            startDate: draft.startDate,
            completionDate: draft.completionDate,
            deadlineDate: draft.deadlineDate,
            targetDays: draft.targetDays,
            entryType: draft.entryType,
            collectionId: draft.collectionId,
            prerequisiteId: draft.prerequisiteId,
            startsAutomaticallyAfterPrerequisites:
                draft.startsAutomaticallyAfterPrerequisites,
          );
      if (!context.mounted || goal.id == null) return;
      final reminderUnavailable = goal.isUpcomingAt(provider.today) &&
          provider.reminderPermissionGranted == false;
      final isUpcoming = goal.isUpcomingAt(provider.today);
      showMotionSnackBar(
        context,
        message: reminderUnavailable
            ? '${goal.isGoal ? 'Goal' : 'Timeline'} created. Allow Motion notifications to receive its start reminder.'
            : isUpcoming
                ? '${goal.isGoal ? 'Goal' : 'Timeline'} created. Start reminder set for 9:00 AM.'
                : '${goal.isGoal ? 'Goal' : 'Timeline'} created.',
        icon: reminderUnavailable
            ? Icons.notifications_off_outlined
            : isUpcoming
                ? Icons.notifications_active_outlined
                : Icons.check_circle_outline_rounded,
        iconColor: reminderUnavailable ? Colors.orange : AppColor.blueMainColor,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoalDetailPage(goalId: goal.id!),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      showMotionSnackBar(
        context,
        message: _message(error),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
    }
  }

  Future<void> _manageCollections(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const TimelineCollectionsPage(),
      ),
    );
  }

  static String _message(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(State|Argument)Error: '), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timelines'),
        actions: [
          IconButton(
            tooltip: 'New Timeline or Goal',
            onPressed: () => _createGoal(context),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Manage Collections',
            onPressed: () => _manageCollections(context),
            icon: const Icon(Icons.folder_open_rounded),
          ),
        ],
      ),
      body: Consumer<GoalTrackerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.goals.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.blueMainColor),
            );
          }
          if (provider.error != null && provider.goals.isEmpty) {
            return _GoalLoadError(
              onRetry: provider.refresh,
              message: _message(provider.error!),
            );
          }
          final showCollectionProgression =
              _showsCollectionProgression(provider);
          final selectedCollection = provider.collectionById(
            provider.selectedCollectionId,
          );
          return RefreshIndicator(
            color: AppColor.blueMainColor,
            onRefresh: provider.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _GoalOverview(provider: provider),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: _CollectionFilters(provider: provider),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  sliver: SliverToBoxAdapter(
                    child: _GoalFilters(provider: provider),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            showCollectionProgression &&
                                    selectedCollection != null
                                ? selectedCollection.name
                                : switch (provider.filter) {
                                    GoalFilter.all => 'All Entries',
                                    GoalFilter.active => 'Ongoing',
                                    GoalFilter.achieved => 'Completed',
                                    GoalFilter.failed => 'Failed',
                                  },
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 13.5,
                              fontweight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${provider.filteredGoals.length}',
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 11,
                            fontweight: FontWeight.w800,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.filteredGoals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _GoalEmptyState(
                      title: provider.goals.isEmpty
                          ? 'No timelines or goals yet'
                          : switch (provider.filter) {
                              GoalFilter.active => 'No ongoing entries',
                              GoalFilter.achieved => 'No completed entries',
                              GoalFilter.failed => 'No failed attempts',
                              GoalFilter.all => 'No entries',
                            },
                      message: provider.goals.isEmpty
                          ? 'Create a timeline or goal and Motion will count every day with you.'
                          : 'Choose another filter or collection to see your entries.',
                      showCreateButton: provider.goals.isEmpty,
                      onCreate: () => _createGoal(context),
                    ),
                  )
                else if (showCollectionProgression)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverToBoxAdapter(
                      child: _CollectionProgression(
                        provider: provider,
                        goals: provider.filteredGoals,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.separated(
                      itemCount: provider.filteredGoals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ProviderGoalCard(
                          provider: provider,
                          goal: provider.filteredGoals[index],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _showsCollectionProgression(GoalTrackerProvider provider) {
  if (provider.showAllCollections || provider.selectedCollectionId == null) {
    return false;
  }
  return provider.filteredGoals.any(
    (goal) =>
        provider.prerequisiteIdsFor(goal).isNotEmpty ||
        provider.dependentsFor(goal).isNotEmpty,
  );
}

class _GoalOverview extends StatelessWidget {
  const _GoalOverview({required this.provider});

  final GoalTrackerProvider provider;

  @override
  Widget build(BuildContext context) {
    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              icon: Icons.timeline_rounded,
              value: provider.goals.length,
              label: 'Total',
              color: AppColor.blueMainColor,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              icon: Icons.timelapse_rounded,
              value: provider.activeCount,
              label: 'Ongoing',
              color: Colors.orange,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              icon: Icons.check_circle_outline_rounded,
              value: provider.achievedCount,
              label: 'Completed',
              color: Colors.green,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              icon: Icons.cancel_outlined,
              value: provider.failedCount,
              label: 'Failed',
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 17,
            fontweight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 9.5,
            fontweight: FontWeight.w700,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }
}

class _CollectionFilters extends StatelessWidget {
  const _CollectionFilters({required this.provider});

  final GoalTrackerProvider provider;

  @override
  Widget build(BuildContext context) {
    final items = <({int? id, String label, int count})>[
      (
        id: null,
        label: 'Uncategorized',
        count: provider.entryCountForCollection(null)
      ),
      ...provider.collections.map(
        (collection) => (
          id: collection.id,
          label: collection.name,
          count: provider.entryCountForCollection(collection.id),
        ),
      ),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CollectionChip(
              label: 'All',
              count: provider.goals.length,
              selected: provider.showAllCollections,
              onTap: provider.showEveryCollection,
            );
          }
          final item = items[index - 1];
          return _CollectionChip(
            label: item.label,
            count: item.count,
            selected: !provider.showAllCollections &&
                provider.selectedCollectionId == item.id,
            onTap: () => provider.filterByCollection(item.id),
          );
        },
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppColor.blueMainColor.withValues(alpha: isDark ? 0.22 : 0.11)
          : isDark
              ? Colors.white.withValues(alpha: 0.045)
              : Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              Icon(
                label == 'All'
                    ? Icons.dashboard_outlined
                    : label == 'Uncategorized'
                        ? Icons.inbox_outlined
                        : Icons.folder_outlined,
                size: 15,
                color: selected ? AppColor.blueMainColor : Colors.blueGrey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? AppColor.blueMainColor : Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 9,
                  fontweight: FontWeight.w800,
                  color: selected ? AppColor.blueMainColor : Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalFilters extends StatelessWidget {
  const _GoalFilters({required this.provider});

  final GoalTrackerProvider provider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: GoalFilter.values.map((filter) {
          final selected = provider.filter == filter;
          final label = switch (filter) {
            GoalFilter.all => 'All',
            GoalFilter.active => 'Ongoing',
            GoalFilter.achieved => 'Completed',
            GoalFilter.failed => 'Failed',
          };
          return Expanded(
            child: InkWell(
              onTap: () => provider.setFilter(filter),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 11,
                    fontweight: selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected ? AppColor.blueMainColor : Colors.blueGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _CollectionProgression extends StatelessWidget {
  const _CollectionProgression({
    required this.provider,
    required this.goals,
  });

  final GoalTrackerProvider provider;
  final List<MotionGoal> goals;

  @override
  Widget build(BuildContext context) {
    final linked = goals
        .where(
          (goal) =>
              provider.prerequisiteIdsFor(goal).isNotEmpty ||
              provider.dependentsFor(goal).isNotEmpty,
        )
        .toList(growable: false);
    final linkedIds = linked.map((goal) => goal.id).whereType<int>().toSet();
    final independent = goals
        .where((goal) => !linkedIds.contains(goal.id))
        .toList(growable: false)
      ..sort(_compareProgressionGoals);
    final groups = _buildProgressionGroups(linked, provider);

    return Column(
      key: const Key('collectionProgression'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressionSectionLabel(
          icon: Icons.account_tree_outlined,
          title: 'Progression',
          count: linked.length,
          color: AppColor.blueMainColor,
        ),
        const SizedBox(height: 10),
        ...groups.indexed.expand((entry) {
          final index = entry.$1;
          final group = entry.$2;
          return <Widget>[
            if (groups.length > 1) ...[
              Text(
                'PATH ${index + 1}',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 9,
                  fontweight: FontWeight.w900,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 7),
            ],
            _ProgressionGroup(provider: provider, goals: group),
            if (index != groups.length - 1) const SizedBox(height: 18),
          ];
        }),
        if (independent.isNotEmpty) ...[
          const SizedBox(height: 22),
          _ProgressionSectionLabel(
            icon: Icons.view_list_outlined,
            title: 'Other entries',
            count: independent.length,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 10),
          ...independent.indexed.expand(
            (entry) => <Widget>[
              _ProviderGoalCard(provider: provider, goal: entry.$2),
              if (entry.$1 != independent.length - 1)
                const SizedBox(height: 10),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProgressionSectionLabel extends StatelessWidget {
  const _ProgressionSectionLabel({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12.5,
              fontweight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$count',
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 10,
            fontweight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProgressionGroup extends StatelessWidget {
  const _ProgressionGroup({required this.provider, required this.goals});

  final GoalTrackerProvider provider;
  final List<MotionGoal> goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < goals.length; index++) ...[
          Builder(
            builder: (context) {
              final previousGoal = index == 0 ? null : goals[index - 1];
              final nextGoal =
                  index == goals.length - 1 ? null : goals[index + 1];
              final hasIncomingConnection = previousGoal != null &&
                  _isDirectProgressionStep(
                    provider,
                    prerequisite: previousGoal,
                    dependent: goals[index],
                  );
              final hasOutgoingConnection = nextGoal != null &&
                  _isDirectProgressionStep(
                    provider,
                    prerequisite: goals[index],
                    dependent: nextGoal,
                  );
              return _ProgressionStep(
                provider: provider,
                goal: goals[index],
                previousGoal: hasIncomingConnection ? previousGoal : null,
                hasNext: hasOutgoingConnection,
              );
            },
          ),
          if (index < goals.length - 1 &&
              _isDirectProgressionStep(
                provider,
                prerequisite: goals[index],
                dependent: goals[index + 1],
              ))
            _ProgressionGap(goal: goals[index]),
        ],
      ],
    );
  }
}

bool _isDirectProgressionStep(
  GoalTrackerProvider provider, {
  required MotionGoal prerequisite,
  required MotionGoal dependent,
}) {
  final prerequisiteId = prerequisite.id;
  return prerequisiteId != null &&
      provider.prerequisiteIdsFor(dependent).contains(prerequisiteId);
}

class _ProgressionStep extends StatelessWidget {
  const _ProgressionStep({
    required this.provider,
    required this.goal,
    required this.previousGoal,
    required this.hasNext,
  });

  final GoalTrackerProvider provider;
  final MotionGoal goal;
  final MotionGoal? previousGoal;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final color = _goalStatusColor(
      goal,
      today: provider.today,
      isPaused: provider.isPaused(goal),
    );
    final incomingColor = previousGoal == null
        ? Colors.transparent
        : _progressionConnectorColor(previousGoal!);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (previousGoal != null)
                  Positioned(
                    left: 16,
                    top: 0,
                    height: 24,
                    width: 2,
                    child: _ProgressionLine(
                      color: incomingColor,
                      dashed: !previousGoal!.isAchieved,
                    ),
                  ),
                if (hasNext)
                  Positioned(
                    left: 16,
                    top: 24,
                    bottom: 0,
                    width: 2,
                    child: _ProgressionLine(
                      color: _progressionConnectorColor(goal),
                      dashed: !goal.isAchieved,
                    ),
                  ),
                Positioned(
                  left: 6,
                  top: 14,
                  child: Container(
                    key: Key('progressionNode_${goal.id}'),
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      goal.isLocked
                          ? Icons.lock_rounded
                          : goal.isFailed
                              ? Icons.close_rounded
                              : goal.isAchieved
                                  ? Icons.check_rounded
                                  : goal.isUpcomingAt(provider.today)
                                      ? Icons.schedule_rounded
                                      : Icons.play_arrow_rounded,
                      size: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _ProviderGoalCard(provider: provider, goal: goal),
          ),
        ],
      ),
    );
  }
}

class _ProgressionGap extends StatelessWidget {
  const _ProgressionGap({required this.goal});

  final MotionGoal goal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: SizedBox(
                width: 2,
                height: 10,
                child: _ProgressionLine(
                  color: _progressionConnectorColor(goal),
                  dashed: !goal.isAchieved,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
      ),
    );
  }
}

class _ProgressionLine extends StatelessWidget {
  const _ProgressionLine({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressionLinePainter(color: color, dashed: dashed),
    );
  }
}

class _ProgressionLinePainter extends CustomPainter {
  const _ProgressionLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    if (!dashed) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    const dash = 4.0;
    const gap = 3.0;
    for (var y = 0.0; y < size.height; y += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressionLinePainter oldDelegate) {
    return color != oldDelegate.color || dashed != oldDelegate.dashed;
  }
}

class _ProviderGoalCard extends StatelessWidget {
  const _ProviderGoalCard({required this.provider, required this.goal});

  final GoalTrackerProvider provider;
  final MotionGoal goal;

  @override
  Widget build(BuildContext context) {
    return _GoalCard(
      goal: goal,
      today: provider.today,
      collection: provider.collectionById(goal.collectionId),
      activeDays: provider.activeDaysFor(goal),
      isPaused: provider.isPaused(goal),
      prerequisite: provider.primaryPrerequisiteFor(goal),
      attemptNumber: provider.attemptNumberFor(goal),
      showAttemptNumber: provider.isPartOfAttemptSeries(goal),
    );
  }
}

List<List<MotionGoal>> _buildProgressionGroups(
  List<MotionGoal> goals,
  GoalTrackerProvider provider,
) {
  final goalsById = <int, MotionGoal>{
    for (final goal in goals)
      if (goal.id != null) goal.id!: goal,
  };
  final adjacency = <int, Set<int>>{
    for (final id in goalsById.keys) id: <int>{},
  };
  for (final goal in goalsById.values) {
    for (final prerequisiteId in provider.prerequisiteIdsFor(goal)) {
      if (!goalsById.containsKey(prerequisiteId)) continue;
      adjacency[goal.id!]!.add(prerequisiteId);
      adjacency[prerequisiteId]!.add(goal.id!);
    }
  }

  final visited = <int>{};
  final groups = <List<MotionGoal>>[];
  for (final startId in goalsById.keys) {
    if (!visited.add(startId)) continue;
    final component = <int>{startId};
    final pending = <int>[startId];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final next in adjacency[current] ?? const <int>{}) {
        if (visited.add(next)) {
          component.add(next);
          pending.add(next);
        }
      }
    }
    groups.add(_topologicalProgression(component, goalsById, provider));
  }
  groups.sort((first, second) {
    if (first.isEmpty) return 1;
    if (second.isEmpty) return -1;
    return _compareProgressionGoals(first.first, second.first);
  });
  return groups;
}

List<MotionGoal> _topologicalProgression(
  Set<int> component,
  Map<int, MotionGoal> goalsById,
  GoalTrackerProvider provider,
) {
  final indegree = <int, int>{};
  for (final id in component) {
    final goal = goalsById[id]!;
    indegree[id] =
        provider.prerequisiteIdsFor(goal).where(component.contains).length;
  }
  final ready = component.where((id) => indegree[id] == 0).toList()
    ..sort((a, b) => _compareProgressionGoals(goalsById[a]!, goalsById[b]!));
  final ordered = <MotionGoal>[];
  while (ready.isNotEmpty) {
    final id = ready.removeAt(0);
    final goal = goalsById[id]!;
    ordered.add(goal);
    for (final dependent in provider.dependentsFor(goal)) {
      final dependentId = dependent.id;
      if (dependentId == null || !component.contains(dependentId)) continue;
      indegree[dependentId] = indegree[dependentId]! - 1;
      if (indegree[dependentId] == 0) {
        ready.add(dependentId);
        ready.sort(
            (a, b) => _compareProgressionGoals(goalsById[a]!, goalsById[b]!));
      }
    }
  }
  if (ordered.length != component.length) {
    final remaining = component
        .where((id) => ordered.every((goal) => goal.id != id))
        .map((id) => goalsById[id]!)
        .toList()
      ..sort(_compareProgressionGoals);
    ordered.addAll(remaining);
  }
  return ordered;
}

int _compareProgressionGoals(MotionGoal first, MotionGoal second) {
  final created = first.createdAtEpochMs.compareTo(second.createdAtEpochMs);
  if (created != 0) return created;
  final start = first.startDate.compareTo(second.startDate);
  if (start != 0) return start;
  return first.name.toLowerCase().compareTo(second.name.toLowerCase());
}

Color _progressionConnectorColor(MotionGoal goal) {
  return goal.isAchieved
      ? Colors.green.withValues(alpha: 0.68)
      : goal.isFailed
          ? Colors.redAccent.withValues(alpha: 0.55)
          : Colors.blueGrey.withValues(alpha: 0.42);
}

Color _goalStatusColor(
  MotionGoal goal, {
  required DateTime today,
  required bool isPaused,
}) {
  if (goal.isLocked) return Colors.blueGrey;
  if (goal.isFailed) return Colors.redAccent;
  if (goal.isAchieved) return Colors.green;
  if (goal.isUpcomingAt(today)) return Colors.deepPurpleAccent;
  if (isPaused) return Colors.orange;
  return AppColor.blueMainColor;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.today,
    required this.collection,
    required this.activeDays,
    required this.isPaused,
    required this.prerequisite,
    required this.attemptNumber,
    required this.showAttemptNumber,
  });

  final MotionGoal goal;
  final DateTime today;
  final MotionTimelineCollection? collection;
  final int activeDays;
  final bool isPaused;
  final MotionGoal? prerequisite;
  final int attemptNumber;
  final bool showAttemptNumber;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = goal.isUpcomingAt(today);
    final statusColor = _goalStatusColor(
      goal,
      today: today,
      isPaused: isPaused,
    );
    final elapsedDays = goal.isGoal ? activeDays : goal.elapsedDaysAt(today);
    final daysUntilStart = goal.effectiveStartDate.difference(today).inDays;
    final deadlineStatus = deadlineStatusFor(goal, today);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoalDetailPage(goalId: goal.id!),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: MotionPanel(
        padding: const EdgeInsets.fromLTRB(13, 13, 9, 13),
        borderRadius: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                goal.isLocked
                    ? Icons.lock_outline_rounded
                    : goal.isFailed
                        ? Icons.close_rounded
                        : goal.isAchieved
                            ? Icons.check_rounded
                            : isUpcoming
                                ? Icons.schedule_rounded
                                : goal.isGoal
                                    ? Icons.flag_outlined
                                    : Icons.timeline_rounded,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 13.5,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _EntryLabel(
                        icon: goal.isGoal
                            ? Icons.flag_outlined
                            : Icons.timeline_rounded,
                        label: goal.isGoal ? 'GOAL' : 'TIMELINE',
                        color: goal.isGoal
                            ? Colors.orange
                            : AppColor.blueMainColor,
                      ),
                      _EntryLabel(
                        icon: collection == null
                            ? Icons.inbox_outlined
                            : Icons.folder_outlined,
                        label:
                            collection?.name.toUpperCase() ?? 'UNCATEGORIZED',
                        color: Colors.blueGrey,
                      ),
                      if (showAttemptNumber)
                        _EntryLabel(
                          icon: Icons.replay_rounded,
                          label: 'ATTEMPT $attemptNumber',
                          color: Colors.deepPurpleAccent,
                        ),
                    ],
                  ),
                  if (goal.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      goal.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 9.5,
                        fontweight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                  if (deadlineStatus != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 12,
                          color: deadlineStatus.color,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            deadlineStatus.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subSectionTextStyle(
                              fontsize: 9.5,
                              fontweight: FontWeight.w800,
                              color: deadlineStatus.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        goal.isLocked
                            ? 'Locked'
                            : goal.isFailed
                                ? 'Failed'
                                : isUpcoming
                                    ? 'Upcoming'
                                    : goal.isGoal
                                        ? goal.isAchieved
                                            ? 'Achieved'
                                            : isPaused
                                                ? 'Paused'
                                                : 'Active'
                                        : goal.isAchieved
                                            ? 'Completed'
                                            : 'Ongoing',
                        style: AppTextStyle.subSectionTextStyle(
                          fontsize: 9,
                          fontweight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        height: 10,
                        width: 1,
                        color: Colors.blueGrey.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          goal.isLocked
                              ? 'Complete ${prerequisite?.name ?? 'the prerequisite'} to unlock'
                              : goal.isFailed
                                  ? 'Failed ${MotionDateUtils.formatDisplayDate(goal.failureDate!)}'
                                  : goal.isAchieved
                                      ? 'Completed ${MotionDateUtils.formatDisplayDate(goal.completionDate!)}'
                                      : '${isUpcoming ? 'Starts' : 'Started'} ${MotionDateUtils.formatDisplayDate(goal.effectiveStartDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subSectionTextStyle(
                            fontsize: 9.5,
                            fontweight: FontWeight.normal,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  goal.isLocked
                      ? '--'
                      : '${isUpcoming ? daysUntilStart : elapsedDays}',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 18,
                    fontweight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                Text(
                  goal.isLocked
                      ? 'LOCKED'
                      : isUpcoming
                          ? 'TO START'
                          : elapsedDays == 1
                              ? 'DAY'
                              : 'DAYS',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 8,
                    fontweight: FontWeight.w800,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryLabel extends StatelessWidget {
  const _EntryLabel({
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
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 7.5,
                fontweight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalEmptyState extends StatelessWidget {
  const _GoalEmptyState({
    required this.title,
    required this.message,
    required this.showCreateButton,
    required this.onCreate,
  });

  final String title;
  final String message;
  final bool showCreateButton;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: AppColor.blueMainColor.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: AppColor.blueMainColor,
                size: 27,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 15,
                fontweight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 10.5,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.blueMainColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(132, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalLoadError extends StatelessWidget {
  const _GoalLoadError({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
