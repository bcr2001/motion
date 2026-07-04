import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motion/motion_core/mc_awards/award_definition.dart';
import 'package:motion/motion_core/motion_providers/firebase_pvd/uid_pvd.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/track_pvd.dart';
import 'package:motion/motion_reusable/db_re/sub_ui.dart';
import 'package:motion/motion_themes/mth_styling/app_color.dart';
import 'package:motion/motion_themes/mth_styling/motion_text_styling.dart';
import 'package:provider/provider.dart';

class AwardsPage extends StatelessWidget {
  const AwardsPage({super.key});

  String _hours(double hours) {
    return '${NumberFormat('#,##0.0').format(hours)} hrs';
  }

  String _milestoneHours(int hours) {
    return '${NumberFormat('#,##0').format(hours)} hours';
  }

  Future<double> _retrieveLifetimeHours({
    required SubcategoryTrackerDatabaseProvider tracker,
    required String currentUser,
  }) async {
    final totals =
        await tracker.retrieveAllSubcategoryTotals(currentUser: currentUser);
    final minutes = totals.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );
    return minutes / 60;
  }

  double _progressFor({
    required double trackedHours,
    required MotionAward? currentAward,
    required MotionAward? nextAward,
  }) {
    if (nextAward == null) return 1;
    final lowerBound = currentAward?.requiredHours.toDouble() ?? 0;
    final targetRange = nextAward.requiredHours - lowerBound;
    if (targetRange <= 0) return 1;
    return ((trackedHours - lowerBound) / targetRange).clamp(0, 1).toDouble();
  }

  Widget _awardImage(
    MotionAward award, {
    required bool earned,
    required double size,
    required int cacheWidth,
  }) {
    return Image.asset(
      earned ? award.assetPath : award.lockedAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: earned
                ? AppColor.accountedColor.withValues(alpha: 0.12)
                : Colors.blueGrey.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            color: earned ? AppColor.accountedColor : Colors.blueGrey,
            size: size * 0.42,
          ),
        );
      },
    );
  }

  Widget _featuredAward({
    required BuildContext context,
    required double trackedHours,
    required MotionAward? currentAward,
    required MotionAward? nextAward,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.10) : Colors.black12;
    final featuredAward = currentAward ?? nextAward ?? MotionAwards.all.last;
    final progress = _progressFor(
      trackedHours: trackedHours,
      currentAward: currentAward,
      nextAward: nextAward,
    );
    final remaining =
        nextAward == null ? 0.0 : nextAward.requiredHours - trackedHours;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 174,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.blueMainColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _awardImage(
              featuredAward,
              earned: currentAward != null,
              size: 164,
              cacheWidth: 420,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            currentAward?.name ?? 'Your First Award',
            textAlign: TextAlign.center,
            style: AppTextStyle.sectionTitleTextStyle(fontsize: 22).copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentAward == null
                ? 'Keep tracking to unlock Deer'
                : nextAward == null
                    ? 'Every lifetime award has been unlocked'
                    : '${currentAward.name} Award earned',
            textAlign: TextAlign.center,
            style: AppTextStyle.subSectionTextStyle(
              fontsize: 12,
              fontweight: FontWeight.normal,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metric(
                  label: 'Lifetime tracked',
                  value: _hours(trackedHours),
                ),
              ),
              Container(
                height: 34,
                width: 1,
                color: Colors.blueGrey.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _metric(
                  label: nextAward == null ? 'Status' : 'Next award',
                  value: nextAward?.name ?? 'Complete',
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  AppColor.blueMainColor.withValues(alpha: 0.14),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColor.blueMainColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  nextAward == null
                      ? 'Collection complete'
                      : '${_hours(remaining.clamp(0, double.infinity).toDouble())} remaining',
                  style: AppTextStyle.subSectionTextStyle(
                    fontsize: 10.5,
                    fontweight: FontWeight.w700,
                    color: AppColor.blueMainColor,
                  ),
                ),
              ),
              if (nextAward != null)
                Text(
                  _milestoneHours(nextAward.requiredHours),
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

  Widget _metric({
    required String label,
    required String value,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.subSectionTextStyle(
            fontsize: 10.5,
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
            fontweight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _awardTile({
    required BuildContext context,
    required MotionAward award,
    required bool earned,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDarkMode
        ? AppColor.darkModeContentWidget
        : AppColor.lightModeContentWidget;
    final borderColor = earned
        ? AppColor.accountedColor.withValues(alpha: 0.32)
        : isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize =
              constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight;

          return Stack(
            alignment: Alignment.center,
            children: [
              _awardImage(
                award,
                earned: earned,
                size: imageSize,
                cacheWidth: 450,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color: earned
                        ? AppColor.accountedColor.withValues(alpha: 0.16)
                        : Colors.blueGrey.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    earned ? Icons.check_rounded : Icons.lock_outline_rounded,
                    size: 15,
                    color: earned ? Colors.green : Colors.blueGrey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _awardsContent({
    required BuildContext context,
    required double trackedHours,
  }) {
    final currentAward = MotionAwards.earnedAt(trackedHours);
    final nextAward = MotionAwards.nextAfter(trackedHours);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _featuredAward(
                context: context,
                trackedHours: trackedHours,
                currentAward: currentAward,
                nextAward: nextAward,
              ),
              const SizedBox(height: 22),
              Text(
                'Award Collection',
                style: AppTextStyle.sectionTitleTextStyle(fontsize: 18).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${MotionAwards.all.where((award) => trackedHours >= award.requiredHours).length} of ${MotionAwards.all.length} unlocked',
                style: AppTextStyle.subSectionTextStyle(
                  fontsize: 11.5,
                  fontweight: FontWeight.normal,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.94,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final award = MotionAwards.all[index];
                return _awardTile(
                  context: context,
                  award: award,
                  earned: trackedHours >= award.requiredHours,
                );
              },
              childCount: MotionAwards.all.length,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awards'),
      ),
      body: Consumer2<UserUidProvider, SubcategoryTrackerDatabaseProvider>(
        builder: (context, user, tracker, child) {
          final currentUser = user.userUid;
          if (currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CachedFutureBuilder<double>(
            cacheKey: 'awards-$currentUser-${tracker.refreshKey}',
            futureFactory: () => _retrieveLifetimeHours(
              tracker: tracker,
              currentUser: currentUser,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return _awardsContent(
                context: context,
                trackedHours: snapshot.data ?? 0,
              );
            },
          );
        },
      ),
    );
  }
}
