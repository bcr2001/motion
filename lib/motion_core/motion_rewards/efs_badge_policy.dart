import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';
import 'package:motion/motion_core/motion_utils/motion_date_utils.dart';

enum EfsBadgeLevel {
  timeNovice,
  focusedBeginner,
  timePro,
  timeMaster,
  timeWizard,
}

enum BadgePaceDifficulty {
  comfortable,
  challenging,
  veryDifficult,
  notAttainable,
  maintenance,
}

extension BadgePaceDifficultyLabel on BadgePaceDifficulty {
  String get label => switch (this) {
        BadgePaceDifficulty.comfortable => 'Comfortable',
        BadgePaceDifficulty.challenging => 'Challenging',
        BadgePaceDifficulty.veryDifficult => 'Very Difficult',
        BadgePaceDifficulty.notAttainable => 'Not Attainable',
        BadgePaceDifficulty.maintenance => 'Maintenance',
      };
}

class EfsBadge {
  final EfsBadgeLevel level;
  final String name;
  final String rangeLabel;
  final String description;
  final double minimumScore;
  final double maximumScore;

  const EfsBadge({
    required this.level,
    required this.name,
    required this.rangeLabel,
    required this.description,
    required this.minimumScore,
    required this.maximumScore,
  });

  bool includes(double score) {
    return score >= minimumScore && score <= maximumScore;
  }
}

class EfsBadgePolicy {
  static const int topBadgeMaintenanceXp = 92;

  static const badges = [
    EfsBadge(
      level: EfsBadgeLevel.timeNovice,
      name: 'Time Novice',
      rangeLabel: '0-19',
      description: 'Just starting out on your time management journey.',
      minimumScore: 0,
      maximumScore: 19.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.focusedBeginner,
      name: 'Focused Beginner',
      rangeLabel: '20-39',
      description: 'Making progress and developing good time habits.',
      minimumScore: 20,
      maximumScore: 39.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timePro,
      name: 'Time Pro',
      rangeLabel: '40-59',
      description: 'Efficiently managing tasks and prioritizing effectively.',
      minimumScore: 40,
      maximumScore: 59.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timeMaster,
      name: 'Time Master',
      rangeLabel: '60-79',
      description: 'Exceptional time management skills and productivity.',
      minimumScore: 60,
      maximumScore: 79.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timeWizard,
      name: 'Time Wizard',
      rangeLabel: '80+',
      description: 'The ultimate time master, achieving peak efficiency.',
      minimumScore: 80,
      maximumScore: 100,
    ),
  ];

  static EfsBadge badgeForScore(double score) {
    final normalizedScore = score.clamp(0, 100).toDouble();

    return badges.firstWhere(
      (badge) => badge.includes(normalizedScore),
      orElse: () => badges.first,
    );
  }

  static EfsBadge? nextBadgeForScore(double score) {
    final normalizedScore = score.clamp(0, 100).toDouble();

    for (final badge in badges) {
      if (badge.minimumScore > normalizedScore) {
        return badge;
      }
    }

    return null;
  }

  static NextBadgeProgress nextBadgeProgress({
    required double currentScore,
    required int currentYearXp,
    required int trackedDays,
    double recentAverageDailyXp = 0,
    DateTime? today,
  }) {
    final normalizedScore = currentScore.clamp(0, 100).toDouble();
    final currentBadge = badgeForScore(normalizedScore);
    final nextBadge = nextBadgeForScore(normalizedScore);

    if (nextBadge == null) {
      return NextBadgeProgress.topBadge(
        currentBadge: currentBadge,
        currentScore: normalizedScore,
        recentAverageDailyXp: recentAverageDailyXp,
      );
    }

    final bandSize = nextBadge.minimumScore - currentBadge.minimumScore;
    final progress = bandSize <= 0
        ? 1.0
        : ((normalizedScore - currentBadge.minimumScore) / bandSize)
            .clamp(0.0, 1.0)
            .toDouble();

    final currentDate = today == null
        ? MotionDateUtils.today()
        : MotionDateUtils.dateOnly(today);
    final daysRemaining = _daysRemainingInYear(currentDate);
    final totalScoredDays = trackedDays + daysRemaining;
    final targetYearXp = ((nextBadge.minimumScore / 100) *
            MotionXpPolicy.maxDailyXp *
            totalScoredDays)
        .ceil();
    final xpGap = (targetYearXp - currentYearXp).clamp(0, 1 << 31).toInt();
    final averageDailyXp = daysRemaining == 0 ? 0.0 : xpGap / daysRemaining;
    final paceDifficulty = _paceDifficulty(
      requiredAverageDailyXp: averageDailyXp,
      recentAverageDailyXp: recentAverageDailyXp,
    );

    return NextBadgeProgress(
      currentBadge: currentBadge,
      nextBadge: nextBadge,
      currentScore: normalizedScore,
      targetScore: nextBadge.minimumScore,
      progress: progress,
      xpGap: xpGap,
      daysRemaining: daysRemaining,
      averageDailyXp: averageDailyXp,
      recentAverageDailyXp: recentAverageDailyXp,
      paceDifficulty: paceDifficulty,
      isTopBadge: false,
      isAttainableThisYear: paceDifficulty != BadgePaceDifficulty.notAttainable,
    );
  }

  static int actionableDailyTarget(NextBadgeProgress progress) {
    if (progress.isTopBadge) return topBadgeMaintenanceXp;
    if (!progress.isAttainableThisYear) return 0;
    return progress.averageDailyXp.ceil();
  }

  static List<BadgeXpTarget> dailyXpTargets(int targetXp) {
    final cappedTarget = targetXp.clamp(0, MotionXpPolicy.maxDailyXp).toInt();
    if (cappedTarget == 0) return const [];

    const targetCaps = [
      BadgeXpTarget(label: 'Education', xp: 20),
      BadgeXpTarget(label: 'Work', xp: 25),
      BadgeXpTarget(label: 'Skills', xp: 20),
      BadgeXpTarget(label: 'Self Development', xp: 20),
      BadgeXpTarget(label: 'Sleep', xp: 25),
      BadgeXpTarget(label: 'Tracking Bonus', xp: 5),
    ];

    var order = 0;
    final rawTargets = targetCaps.map((target) {
      final rawXp = cappedTarget * target.xp / MotionXpPolicy.maxDailyXp;
      return _RawBadgeXpTarget(
        label: target.label,
        cap: target.xp,
        floorXp: rawXp.floor(),
        remainder: rawXp - rawXp.floor(),
        order: order++,
      );
    }).toList();

    var allocatedXp = rawTargets.fold<int>(
      0,
      (total, target) => total + target.floorXp,
    );
    var remainingXp = cappedTarget - allocatedXp;

    rawTargets.sort((a, b) => b.remainder.compareTo(a.remainder));
    for (final target in rawTargets) {
      if (remainingXp <= 0) break;
      if (target.floorXp >= target.cap) continue;
      target.floorXp++;
      remainingXp--;
    }

    rawTargets.sort((a, b) => a.order.compareTo(b.order));

    return rawTargets
        .where((target) => target.floorXp > 0)
        .map((target) => BadgeXpTarget(
              label: target.label,
              xp: target.floorXp,
            ))
        .toList();
  }

  static int _daysRemainingInYear(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    final endOfYear = DateTime(date.year, 12, 31);
    if (today.isAfter(endOfYear)) return 0;
    return endOfYear.difference(today).inDays + 1;
  }

  static BadgePaceDifficulty _paceDifficulty({
    required double requiredAverageDailyXp,
    required double recentAverageDailyXp,
  }) {
    if (requiredAverageDailyXp > MotionXpPolicy.maxDailyXp) {
      return BadgePaceDifficulty.notAttainable;
    }
    if (recentAverageDailyXp > 0 &&
        requiredAverageDailyXp <= recentAverageDailyXp) {
      return BadgePaceDifficulty.comfortable;
    }

    final moderateIncrease = recentAverageDailyXp <= 0
        ? 70.0
        : recentAverageDailyXp +
            (recentAverageDailyXp * 0.25).clamp(10.0, 20.0);
    if (requiredAverageDailyXp <= moderateIncrease &&
        requiredAverageDailyXp < MotionXpPolicy.maxDailyXp * 0.8) {
      return BadgePaceDifficulty.challenging;
    }
    return BadgePaceDifficulty.veryDifficult;
  }
}

class BadgeXpTarget {
  final String label;
  final int xp;

  const BadgeXpTarget({
    required this.label,
    required this.xp,
  });
}

class _RawBadgeXpTarget {
  final String label;
  final int cap;
  int floorXp;
  final double remainder;
  final int order;

  _RawBadgeXpTarget({
    required this.label,
    required this.cap,
    required this.floorXp,
    required this.remainder,
    required this.order,
  });
}

class NextBadgeProgress {
  final EfsBadge currentBadge;
  final EfsBadge? nextBadge;
  final double currentScore;
  final double targetScore;
  final double progress;
  final int xpGap;
  final int daysRemaining;
  final double averageDailyXp;
  final double recentAverageDailyXp;
  final BadgePaceDifficulty paceDifficulty;
  final bool isTopBadge;
  final bool isAttainableThisYear;

  const NextBadgeProgress({
    required this.currentBadge,
    required this.nextBadge,
    required this.currentScore,
    required this.targetScore,
    required this.progress,
    required this.xpGap,
    required this.daysRemaining,
    required this.averageDailyXp,
    required this.recentAverageDailyXp,
    required this.paceDifficulty,
    required this.isTopBadge,
    required this.isAttainableThisYear,
  });

  factory NextBadgeProgress.topBadge({
    required EfsBadge currentBadge,
    required double currentScore,
    double recentAverageDailyXp = 0,
  }) {
    return NextBadgeProgress(
      currentBadge: currentBadge,
      nextBadge: null,
      currentScore: currentScore,
      targetScore: currentBadge.minimumScore,
      progress: 1.0,
      xpGap: 0,
      daysRemaining: 0,
      averageDailyXp: EfsBadgePolicy.topBadgeMaintenanceXp.toDouble(),
      recentAverageDailyXp: recentAverageDailyXp,
      paceDifficulty: BadgePaceDifficulty.maintenance,
      isTopBadge: true,
      isAttainableThisYear: true,
    );
  }
}
