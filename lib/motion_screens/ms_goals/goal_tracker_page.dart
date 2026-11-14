import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
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
            entryType: draft.entryType,
            collectionId: draft.collectionId,
          );
      if (!context.mounted || goal.id == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoalDetailPage(goalId: goal.id!),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
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
                            switch (provider.filter) {
                              GoalFilter.all => 'All Entries',
                              GoalFilter.active => 'Ongoing',
                              GoalFilter.achieved => 'Completed',
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
                          : provider.filter == GoalFilter.active
                              ? 'No ongoing entries'
                              : 'No completed entries',
                      message: provider.goals.isEmpty
                          ? 'Create a timeline or goal and Motion will count every day with you.'
                          : 'Choose another filter or collection to see your entries.',
                      showCreateButton: provider.goals.isEmpty,
                      onCreate: () => _createGoal(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.separated(
                      itemCount: provider.filteredGoals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _GoalCard(
                          goal: provider.filteredGoals[index],
                          today: provider.today,
                          collection: provider.collectionById(
                            provider.filteredGoals[index].collectionId,
                          ),
                          activeDays: provider.activeDaysFor(
                            provider.filteredGoals[index],
                          ),
                          isPaused: provider.isPaused(
                            provider.filteredGoals[index],
                          ),
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.today,
    required this.collection,
    required this.activeDays,
    required this.isPaused,
  });

  final MotionGoal goal;
  final DateTime today;
  final MotionTimelineCollection? collection;
  final int activeDays;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final statusColor = goal.isAchieved
        ? Colors.green
        : isPaused
            ? Colors.orange
            : AppColor.blueMainColor;
    final elapsedDays = goal.isGoal ? activeDays : goal.elapsedDaysAt(today);
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
                goal.isAchieved
                    ? Icons.check_rounded
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
                        goal.isGoal
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
                          goal.isAchieved
                              ? 'Completed ${MotionDateUtils.formatDisplayDate(goal.completionDate!)}'
                              : 'Started ${MotionDateUtils.formatDisplayDate(goal.startDate)}',
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
                  '$elapsedDays',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 18,
                    fontweight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
                Text(
                  elapsedDays == 1 ? 'DAY' : 'DAYS',
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
