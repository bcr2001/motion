import 'package:flutter/material.dart';
import 'package:motion/motion_core/motion_providers/date_pvd/current_year_pvd.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import 'package:provider/provider.dart';
import '../../motion_themes/mth_app/app_images.dart';
import '../../motion_themes/mth_app/app_strings.dart';
import '../../motion_themes/mth_styling/app_color.dart';
import '../../motion_themes/mth_styling/motion_text_styling.dart';

// A stateless widget that displays a badge assignment table
class BadgeAssignment extends StatelessWidget {
  const BadgeAssignment({super.key});

  Future<NextBadgeProgress> _loadNextBadgeProgress({
    required ExperiencePointTableProvider xpProvider,
    required String currentUser,
    required String currentYear,
  }) async {
    final score = await xpProvider.retrieveYearExperiencePointsEfficiencyScore(
      currentUser: currentUser,
      currentYear: currentYear,
    );
    final totalXp = await xpProvider.retrieveTotalXP(
      currentUser: currentUser,
      isEntire: false,
      year: currentYear,
    );
    final trackedDays = await xpProvider.retrieveYearExperiencePointDays(
      currentUser: currentUser,
      year: currentYear,
    );

    return EfsBadgePolicy.nextBadgeProgress(
      currentScore: score,
      currentYearXp: totalXp,
      trackedDays: trackedDays,
    );
  }

  Widget _badgeIcon(EfsBadgeLevel level) {
    switch (level) {
      case EfsBadgeLevel.timeNovice:
        return getImageAsset("sloth.png", 28, 28);
      case EfsBadgeLevel.focusedBeginner:
        return getImageAsset("dolphin.png", 28, 28);
      case EfsBadgeLevel.timePro:
        return getImageAsset("eagle.png", 28, 28);
      case EfsBadgeLevel.timeMaster:
        return getImageAsset("dragon.png", 28, 28);
      case EfsBadgeLevel.timeWizard:
        return getImageAsset("wizard.png", 28, 28);
    }
  }

  Widget _badgeNameCell(EfsBadge badge) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: _badgeIcon(badge.level),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 14,
                fontweight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guidanceMetric({
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 11,
                fontweight: FontWeight.normal,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subSectionTextStyle(
                fontsize: 13,
                fontweight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextBadgeGuidanceCard({
    required BuildContext context,
    required bool isDarkMode,
    required Color borderColor,
  }) {
    return Consumer3<ExperiencePointTableProvider, UserUidProvider,
        CurrentYearProvider>(builder: (context, xp, user, year, child) {
      final currentUser = user.userUid;
      if (currentUser == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final currentYear = year.currentYear;

      return FutureBuilder<NextBadgeProgress>(
        future: _loadNextBadgeProgress(
          xpProvider: xp,
          currentUser: currentUser,
          currentYear: currentYear,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          final progress = snapshot.data!;
          final nextBadge = progress.nextBadge;
          final progressPercent = (progress.progress * 100).round();
          final averageXp = progress.averageDailyXp.ceil();

          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 36,
                        width: 36,
                        child: _badgeIcon(
                            nextBadge?.level ?? progress.currentBadge.level),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress.isTopBadge
                                  ? 'Top Badge Earned'
                                  : 'Next Badge',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 12,
                                fontweight: FontWeight.normal,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              progress.isTopBadge
                                  ? progress.currentBadge.name
                                  : nextBadge!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 16,
                                fontweight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 8,
                      color: Colors.orange,
                      backgroundColor: Colors.orange.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.isTopBadge
                        ? 'You have reached the highest badge for the year.'
                        : '$progressPercent% toward ${nextBadge!.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subSectionTextStyle(
                      fontsize: 12,
                      fontweight: FontWeight.normal,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _guidanceMetric(
                        label: 'Current EFS',
                        value: progress.currentScore.toStringAsFixed(2),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(width: 8),
                      _guidanceMetric(
                        label: 'Target EFS',
                        value: progress.isTopBadge
                            ? '100.00'
                            : progress.targetScore.toStringAsFixed(2),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                  if (!progress.isTopBadge) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _guidanceMetric(
                          label: 'XP Gap',
                          value: '${progress.xpGap} XP',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 8),
                        _guidanceMetric(
                          label: 'Average Needed',
                          value: '$averageXp XP/day',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.isAttainableThisYear
                          ? 'Maintain this average for ${progress.daysRemaining} days to reach the next badge this year.'
                          : 'This badge is above the remaining daily XP pace for this year.',
                      style: AppTextStyle.subSectionTextStyle(
                        fontsize: 12,
                        fontweight: FontWeight.normal,
                        color: progress.isAttainableThisYear
                            ? Colors.blueGrey
                            : Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final headerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : AppColor.tileBackgroundColor.withValues(alpha: 0.08);
    final alternateRowColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.025)
        : AppColor.tileBackgroundColor.withValues(alpha: 0.035);

    return Scaffold(
      appBar: AppBar(
          title: const Text(AppString.badgeAssignmentTitle)), // AppBar title
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _nextBadgeGuidanceCard(
              context: context,
              isDarkMode: isDarkMode,
              borderColor: borderColor,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.sizeOf(context).width - 32,
                      ),
                      child: DataTable(
                        columnSpacing: 32.0,
                        horizontalMargin: 18,
                        headingRowHeight: 48,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        dividerThickness: 0.6,
                        headingRowColor: WidgetStatePropertyAll(headerColor),
                        border: TableBorder(
                          horizontalInside: BorderSide(color: borderColor),
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              AppString.badgeNameColumn,
                              style: AppTextStyle.subSectionTextStyle(
                                fontsize: 13,
                                fontweight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Text(
                                AppString.efsRangeColumn,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.subSectionTextStyle(
                                  fontsize: 13,
                                  fontweight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: EfsBadgePolicy.badges
                            .asMap()
                            .entries
                            .map(
                              (entry) => DataRow(
                                color: WidgetStatePropertyAll(
                                  entry.key.isEven ? null : alternateRowColor,
                                ),
                                cells: [
                                  DataCell(_badgeNameCell(entry.value)),
                                  DataCell(Center(
                                    child: Text(
                                      entry.value.rangeLabel,
                                      style: AppTextStyle.subSectionTextStyle(
                                        fontsize: 14,
                                        fontweight: FontWeight.normal,
                                        color: AppColor.accountedColor,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
