import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';
import 'package:motion/motion_core/mc_sqlite/database_constants.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';
import 'package:motion/motion_reusable/db_re/sub_logic.dart';
import 'package:motion/motion_reusable/motion_ui/motion_components.dart';
import 'package:motion/motion_reusable/motion_ui/motion_date_picker_dialog.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

import 'daily_review_data.dart';
import 'daily_review_dialogs.dart';

class DailyReviewPage extends StatefulWidget {
  const DailyReviewPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DailyReviewPage> createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  static final DateTime _firstTrackingDate = DateTime(2021, 7, 1);

  late DateTime _selectedDate;
  String? _requestKey;
  Future<DailyReviewData>? _reviewFuture;

  @override
  void initState() {
    super.initState();
    final today = MotionDateUtils.today();
    final requested = MotionDateUtils.dateOnly(widget.initialDate ?? today);
    _selectedDate = requested.isAfter(today) ? today : requested;
  }

  void _selectDate(DateTime date) {
    final normalized = MotionDateUtils.dateOnly(date);
    if (normalized.isBefore(_firstTrackingDate) ||
        normalized.isAfter(MotionDateUtils.today()) ||
        normalized == _selectedDate) {
      return;
    }
    setState(() {
      _selectedDate = normalized;
      _requestKey = null;
    });
  }

  Future<void> _openDatePicker() async {
    final selected = await showMotionDatePickerDialog(
      context: context,
      initialDate: _selectedDate,
      firstDate: _firstTrackingDate,
      lastDate: MotionDateUtils.today(),
      title: 'Select Review Date',
      confirmLabel: 'Open Review',
    );
    if (selected != null) _selectDate(selected);
  }

  List<Assigner> _availableAssignments({
    required AssignerMainProvider assigner,
    required String currentUser,
  }) {
    final available = assigner.assignerItems.where((item) {
      if (item.currentLoggedInUser != currentUser || item.isArchive == 1) {
        return false;
      }
      final created = MotionDateUtils.parseStoredDate(item.dateCreated);
      return created == null || !_selectedDate.isBefore(created);
    }).toList();
    available.sort(
      (first, second) =>
          first.subcategoryName.compareTo(second.subcategoryName),
    );
    return available;
  }

  Future<void> _addBlock({
    required String currentUser,
    required SubcategoryTrackerDatabaseProvider subcategoryProvider,
    required AssignerMainProvider assigner,
  }) async {
    final assignments = _availableAssignments(
      assigner: assigner,
      currentUser: currentUser,
    );
    if (assignments.isEmpty) {
      _showMessage('No subcategories were available on this date.', true);
      return;
    }
    final draft = await showDailyTimeBlockDialog(
      context: context,
      date: _selectedDate,
      assignments: assignments,
    );
    if (draft == null || !mounted) return;
    final assignment = draft.assignment!;
    try {
      await subcategoryProvider.insertIntoSubcategoryTable(
        Subcategories(
          date: MotionDateUtils.formatDbDate(_selectedDate),
          mainCategoryName: assignment.mainCategoryName,
          subcategoryName: assignment.subcategoryName,
          timeSpent: draft.minutes,
          currentLoggedInUser: currentUser,
        ),
      );
      if (mounted) _showMessage('Time block added.', false);
    } catch (error) {
      if (mounted) _showMessage('$error', true);
    }
  }

  Future<void> _editBlock({
    required Subcategories entry,
    required SubcategoryTrackerDatabaseProvider subcategoryProvider,
  }) async {
    final draft = await showDailyTimeBlockDialog(
      context: context,
      date: _selectedDate,
      assignments: const [],
      existingEntry: entry,
    );
    if (draft == null || !mounted) return;
    try {
      await subcategoryProvider.updateSubcategoryTable(
        Subcategories(
          id: entry.id,
          date: entry.date,
          mainCategoryName: entry.mainCategoryName,
          subcategoryName: entry.subcategoryName,
          timeSpent: draft.minutes,
          currentLoggedInUser: entry.currentLoggedInUser,
        ),
      );
      if (mounted) _showMessage('Time block updated.', false);
    } catch (error) {
      if (mounted) _showMessage('$error', true);
    }
  }

  Future<void> _deleteBlock({
    required Subcategories entry,
    required SubcategoryTrackerDatabaseProvider subcategoryProvider,
  }) async {
    if (entry.id == null) return;
    final confirmed = await showDeleteTimeBlockDialog(
      context: context,
      entry: entry,
    );
    if (!confirmed || !mounted) return;
    try {
      await subcategoryProvider.deleteSubcategoryEntry(
        entry.id!,
        deletedSubcategory: entry,
      );
      if (mounted) _showMessage('Time block deleted.', false);
    } catch (error) {
      if (mounted) _showMessage('Could not delete time: $error', true);
    }
  }

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : AppColor.blueMainColor,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Review'),
        actions: [
          IconButton(
            tooltip: 'Select date',
            onPressed: _openDatePicker,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
      body: Consumer4<UserUidProvider, SubcategoryTrackerDatabaseProvider,
          ExperiencePointTableProvider, AssignerMainProvider>(
        builder: (context, user, subcategory, experience, assigner, child) {
          final currentUser = user.userUid;
          if (currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final date = MotionDateUtils.formatDbDate(_selectedDate);
          final requestKey = '$currentUser-$date-'
              '${subcategory.refreshKey}-${experience.refreshKey}';
          if (_requestKey != requestKey) {
            _requestKey = requestKey;
            _reviewFuture = DailyReviewLoader(
              subcategoryProvider: subcategory,
              experienceProvider: experience,
            ).load(currentUser: currentUser, date: date);
          }

          return FutureBuilder<DailyReviewData>(
            future: _reviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _DailyReviewLoading();
              }
              if (snapshot.hasError) {
                return _DailyReviewError(
                  onRetry: () => setState(() => _requestKey = null),
                );
              }
              final data = snapshot.data ??
                  const DailyReviewData(entries: [], xpBreakdown: {});
              final streakChecks = data.streakChecks(
                assignments: assigner.assignerItems,
                currentUser: currentUser,
                selectedDate: _selectedDate,
                today: MotionDateUtils.today(),
              );

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _requestKey = null);
                  await Future<void>.delayed(const Duration(milliseconds: 250));
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                  children: [
                    _DateNavigator(
                      selectedDate: _selectedDate,
                      firstDate: _firstTrackingDate,
                      today: MotionDateUtils.today(),
                      onPrevious: () => _selectDate(
                        _selectedDate.subtract(const Duration(days: 1)),
                      ),
                      onNext: () => _selectDate(
                        _selectedDate.add(const Duration(days: 1)),
                      ),
                      onSelectDate: _openDatePicker,
                    ),
                    const SizedBox(height: 12),
                    _DailyOverview(data: data),
                    const SizedBox(height: 18),
                    const MotionSectionHeader(
                      title: 'Category Summary',
                      subtitle: 'Tracked time and XP earned by category',
                    ),
                    const SizedBox(height: 9),
                    _CategorySummaryPanel(data: data),
                    if (streakChecks.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const MotionSectionHeader(
                        title: 'Streak Checks',
                        subtitle: 'Requirements for the selected date',
                      ),
                      const SizedBox(height: 9),
                      _StreakChecksPanel(checks: streakChecks),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: MotionSectionHeader(
                            title: 'Time Blocks',
                            subtitle: 'Individual entries saved on this date',
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => _addBlock(
                            currentUser: currentUser,
                            subcategoryProvider: subcategory,
                            assigner: assigner,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.blueMainColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    if (data.entries.isEmpty)
                      const MotionPanel(
                        child: MotionEmptyState(
                          icon: Icons.event_note_rounded,
                          title: 'No time recorded',
                          message:
                              'Add a missing block or choose another date.',
                        ),
                      )
                    else
                      for (final entry in data.entries) ...[
                        _TimeBlockTile(
                          entry: entry,
                          onEdit: () => _editBlock(
                            entry: entry,
                            subcategoryProvider: subcategory,
                          ),
                          onDelete: () => _deleteBlock(
                            entry: entry,
                            subcategoryProvider: subcategory,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.selectedDate,
    required this.firstDate,
    required this.today,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime today;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Previous day',
          onPressed: selectedDate.isAfter(firstDate) ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onSelectDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Text(
                    MotionDateUtils.isSameDate(selectedDate, today)
                        ? 'Today'
                        : MotionDateUtils.formatLongDisplayDate(selectedDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 16,
                      fontweight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MotionDateUtils.formatDisplayDate(selectedDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 10.5,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Next day',
          onPressed: selectedDate.isBefore(today) ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _DailyOverview extends StatelessWidget {
  const _DailyOverview({required this.data});

  final DailyReviewData data;

  @override
  Widget build(BuildContext context) {
    return MotionPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColor.blueMainColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColor.blueMainColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '24-Hour Overview',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 15,
                    fontweight: FontWeight.w900,
                  ),
                ),
              ),
              MotionStatusPill(
                label: '${(data.trackedProgress * 100).toStringAsFixed(0)}%',
                color: AppColor.blueMainColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          MotionProgressBar(value: data.trackedProgress, height: 11),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MotionMetric(
                  label: 'Tracked',
                  value: convertMinutesToTime(data.trackedMinutes),
                ),
              ),
              Expanded(
                child: MotionMetric(
                  label: 'Remaining',
                  value: convertMinutesToTime(data.remainingMinutes),
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 19,
                color: Colors.orange,
              ),
              const SizedBox(width: 7),
              Text(
                '${data.totalXp} XP earned',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 12.5,
                  fontweight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${data.entries.length} ${data.entries.length == 1 ? 'block' : 'blocks'}',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 10.5,
                  fontweight: FontWeight.w700,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySummaryPanel extends StatelessWidget {
  const _CategorySummaryPanel({required this.data});

  final DailyReviewData data;

  @override
  Widget build(BuildContext context) {
    final rows = data.categorySummaries;
    if (rows.isEmpty) {
      return const MotionPanel(
        child: MotionEmptyState(
          icon: Icons.category_outlined,
          title: 'No category totals',
        ),
      );
    }
    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _CategoryRow(summary: rows[index]),
            if (index < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.summary});

  final DailyCategorySummary summary;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(summary.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_categoryIcon(summary.name), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12.5,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  convertMinutesToTime(summary.minutes),
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          MotionStatusPill(
            label: '${summary.xp} XP',
            color: summary.xp > 0 ? color : Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}

class _StreakChecksPanel extends StatelessWidget {
  const _StreakChecksPanel({required this.checks});

  final List<DailyStreakCheck> checks;

  @override
  Widget build(BuildContext context) {
    return MotionPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: Column(
        children: [
          for (var index = 0; index < checks.length; index++) ...[
            _StreakCheckRow(check: checks[index]),
            if (index < checks.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _StreakCheckRow extends StatelessWidget {
  const _StreakCheckRow({required this.check});

  final DailyStreakCheck check;

  @override
  Widget build(BuildContext context) {
    final color = check.isMet
        ? AppColor.selfDevelopmentPieChartColor
        : check.isAtRisk
            ? Colors.orange
            : Colors.redAccent;
    final status = check.isMet
        ? 'Met'
        : check.isAtRisk
            ? 'At Risk'
            : 'Missed';
    final requirement = check.requirement > 0
        ? 'Target ${convertMinutesToTime(check.requirement)}'
        : 'Any tracked time';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            check.isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.subcategoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 12.5,
                    fontweight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$requirement | ${convertMinutesToTime(check.trackedMinutes)} tracked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          MotionStatusPill(label: status, color: color),
        ],
      ),
    );
  }
}

class _TimeBlockTile extends StatelessWidget {
  const _TimeBlockTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final Subcategories entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _categoryColor(entry.mainCategoryName);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 3),
                Text(
                  '${entry.mainCategoryName} | ${convertMinutesToTime(entry.timeSpent)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.normal,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit block',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Delete block',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReviewLoading extends StatelessWidget {
  const _DailyReviewLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColor.blueMainColor),
    );
  }
}

class _DailyReviewError extends StatelessWidget {
  const _DailyReviewError({required this.onRetry});

  final VoidCallback onRetry;

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
            const Text('Daily Review could not be loaded.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(String category) {
  return switch (category) {
    MotionCategories.education => AppColor.educationPieChartColor,
    MotionCategories.work => AppColor.workPieChartColor,
    MotionCategories.skills => AppColor.skillsPieChartColor,
    MotionCategories.entertainment => AppColor.entertainmentPieChartColor,
    MotionCategories.selfDevelopment => AppColor.selfDevelopmentPieChartColor,
    MotionCategories.sleep => AppColor.sleepPieChartColor,
    _ => AppColor.blueMainColor,
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    MotionCategories.education => Icons.school_rounded,
    MotionCategories.work => Icons.work_rounded,
    MotionCategories.skills => Icons.psychology_rounded,
    MotionCategories.entertainment => Icons.movie_filter_rounded,
    MotionCategories.selfDevelopment => Icons.self_improvement_rounded,
    MotionCategories.sleep => Icons.bedtime_rounded,
    _ => Icons.category_rounded,
  };
}
