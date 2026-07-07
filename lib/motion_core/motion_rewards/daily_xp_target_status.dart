import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/experience_pvd.dart';
import 'package:motion/motion_core/motion_rewards/efs_badge_policy.dart';

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
  final results = await Future.wait<int>([
    xpProvider.retrieveTotalXP(
      currentUser: currentUser,
      isEntire: false,
      year: currentYear,
    ),
    xpProvider.retrieveYearExperiencePointDays(
      currentUser: currentUser,
      year: currentYear,
    ),
    xpProvider.retrieveDailyExperiencePoints(
      currentUser: currentUser,
      selectedDate: currentDate,
    ),
  ]);

  final progress = EfsBadgePolicy.nextBadgeProgress(
    currentScore: currentScore,
    currentYearXp: results[0],
    trackedDays: results[1],
  );
  final targetXp = progress.isTopBadge
      ? MotionXpPolicy.maxDailyXp
      : progress.averageDailyXp.ceil();

  return DailyXpTargetStatus(
    progress: progress,
    earnedXp: results[2],
    targetXp: targetXp,
  );
}
