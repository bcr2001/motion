import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/goal.dart';
import 'package:motion/motion_core/motion_providers/goal_pvd/goal_tracker_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_screens/ms_goals/goal_detail_page.dart';
import 'package:motion/motion_screens/ms_goals/goal_dialogs.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class GoalTrackerPage extends StatelessWidget {
  const GoalTrackerPage({super.key});

  Future<void> _createGoal(BuildContext context) async {
    final draft = await showGoalEditorDialog(context: context);
    if (draft == null || !context.mounted) return;
    try {
      final goal = await context.read<GoalTrackerProvider>().createGoal(
            name: draft.name,
            description: draft.description,
            startDate: draft.startDate,
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

  static String _message(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(State|Argument)Error: '), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Tracker'),
        actions: [
          IconButton(
            tooltip: 'Create Goal',
            onPressed: () => _createGoal(context),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Refresh goals',
            onPressed: () => context.read<GoalTrackerProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded),
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
                              GoalFilter.all => 'All Goals',
                              GoalFilter.active => 'Active Goals',
                              GoalFilter.achieved => 'Achieved Goals',
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
                          ? 'No goals yet'
                          : 'No ${provider.filter.name} goals',
                      message: provider.goals.isEmpty
                          ? 'Create a goal and Motion will count every day with you.'
                          : 'Choose another filter to see your goals.',
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
              icon: Icons.flag_outlined,
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
              label: 'Active',
              color: Colors.orange,
            ),
          ),
          const _OverviewDivider(),
          Expanded(
            child: _OverviewMetric(
              icon: Icons.check_circle_outline_rounded,
              value: provider.achievedCount,
              label: 'Achieved',
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
            GoalFilter.active => 'Active',
            GoalFilter.achieved => 'Achieved',
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
  const _GoalCard({required this.goal, required this.today});

  final MotionGoal goal;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final statusColor = goal.isAchieved ? Colors.green : AppColor.blueMainColor;
    final elapsedDays = goal.elapsedDaysAt(today);
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
                goal.isAchieved ? Icons.check_rounded : Icons.flag_outlined,
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
                  const SizedBox(height: 6),
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
                        goal.isAchieved ? 'Achieved' : 'Active',
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
                Icons.flag_outlined,
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
                label: const Text('Create Goal'),
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
