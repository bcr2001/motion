import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

class DailyXpTargetStatus {
  final NextBadgeProgress progress;
  final int earnedXp;
  final int targetXp;

  const DailyXpTargetStatus({
    required this.progress,
    required this.earnedXp,
    required this.targetXp,
  });

  bool get hasMetTarget => targetXp > 0 && earnedXp >= targetXp;
}

Future<DailyXpTargetStatus> loadDailyXpTargetStatus({
  required ExperiencePointTableProvider xpProvider,
  required String currentUser,
  required String currentYear,
  required String currentDate,
  required double currentScore,
}) async {
  final results = await Future.wait<Object>([
    loadNextBadgeProgress(
      xpProvider: xpProvider,
      currentUser: currentUser,
      currentYear: currentYear,
      currentDate: currentDate,
      currentScore: currentScore,
    ),
    xpProvider.retrieveDailyExperiencePoints(
      currentUser: currentUser,
      selectedDate: currentDate,
    ),
  ]);
  final progress = results[0] as NextBadgeProgress;
  final targetXp = EfsBadgePolicy.actionableDailyTarget(progress);

  return DailyXpTargetStatus(
    progress: progress,
    earnedXp: results[1] as int,
    targetXp: targetXp,
  );
}

Future<NextBadgeProgress> loadNextBadgeProgress({
  required ExperiencePointTableProvider xpProvider,
  required String currentUser,
  required String currentYear,
  required String currentDate,
  required double currentScore,
}) async {
  final today =
      MotionDateUtils.parseStoredDate(currentDate) ?? MotionDateUtils.today();
  final yesterday = today.subtract(const Duration(days: 1));
  final recentStart = today.subtract(const Duration(days: 30));
  final beforeDate = MotionDateUtils.formatDbDate(today);

  final results = await Future.wait<Object>([
    xpProvider.retrieveYearExperiencePointsBeforeDate(
      currentUser: currentUser,
      year: currentYear,
      beforeDate: beforeDate,
    ),
    xpProvider.retrieveYearExperiencePointDaysBeforeDate(
      currentUser: currentUser,
      year: currentYear,
      beforeDate: beforeDate,
    ),
    xpProvider.retrieveAverageDailyExperiencePoints(
      currentUser: currentUser,
      firstDate: MotionDateUtils.formatDbDate(recentStart),
      lastDate: MotionDateUtils.formatDbDate(yesterday),
    ),
  ]);

  return EfsBadgePolicy.nextBadgeProgress(
    currentScore: currentScore,
    currentYearXp: results[0] as int,
    trackedDays: results[1] as int,
    recentAverageDailyXp: results[2] as double,
    today: today,
  );
}
