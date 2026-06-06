import 'package:motion/motion_core/mc_sqlite/xp_policy.dart';

enum EfsBadgeLevel {
  timeNovice,
  focusedBeginner,
  timePro,
  timeMaster,
  timeWizard,
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
  static const badges = [
    EfsBadge(
      level: EfsBadgeLevel.timeNovice,
      name: 'Time Novice',
      rangeLabel: '0-24',
      description: 'Just starting out on your time management journey.',
      minimumScore: 0,
      maximumScore: 24.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.focusedBeginner,
      name: 'Focused Beginner',
      rangeLabel: '25-49',
      description: 'Making progress and developing good time habits.',
      minimumScore: 25,
      maximumScore: 49.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timePro,
      name: 'Time Pro',
      rangeLabel: '50-74',
      description: 'Efficiently managing tasks and prioritizing effectively.',
      minimumScore: 50,
      maximumScore: 74.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timeMaster,
      name: 'Time Master',
      rangeLabel: '75-99',
      description: 'Exceptional time management skills and productivity.',
      minimumScore: 75,
      maximumScore: 99.999,
    ),
    EfsBadge(
      level: EfsBadgeLevel.timeWizard,
      name: 'Time Wizard',
      rangeLabel: '100',
      description: 'The ultimate time master, achieving peak efficiency.',
      minimumScore: 100,
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
    DateTime? today,
  }) {
    final normalizedScore = currentScore.clamp(0, 100).toDouble();
    final currentBadge = badgeForScore(normalizedScore);
    final nextBadge = nextBadgeForScore(normalizedScore);

    if (nextBadge == null) {
      return NextBadgeProgress.topBadge(
        currentBadge: currentBadge,
        currentScore: normalizedScore,
      );
    }

    final bandSize = nextBadge.minimumScore - currentBadge.minimumScore;
    final progress = bandSize <= 0
        ? 1.0
        : ((normalizedScore - currentBadge.minimumScore) / bandSize)
            .clamp(0.0, 1.0)
            .toDouble();

    final currentDate = today ?? DateTime.now();
    final daysRemaining = _daysRemainingInYear(currentDate);
    final totalScoredDays = trackedDays + daysRemaining;
    final targetYearXp = ((nextBadge.minimumScore / 100) *
            MotionXpPolicy.maxDailyXp *
            totalScoredDays)
        .ceil();
    final xpGap = (targetYearXp - currentYearXp).clamp(0, 1 << 31).toInt();
    final averageDailyXp = daysRemaining == 0 ? 0.0 : xpGap / daysRemaining;

    return NextBadgeProgress(
      currentBadge: currentBadge,
      nextBadge: nextBadge,
      currentScore: normalizedScore,
      targetScore: nextBadge.minimumScore,
      progress: progress,
      xpGap: xpGap,
      daysRemaining: daysRemaining,
      averageDailyXp: averageDailyXp,
      isTopBadge: false,
      isAttainableThisYear: averageDailyXp <= MotionXpPolicy.maxDailyXp,
    );
  }

  static int _daysRemainingInYear(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    final endOfYear = DateTime(date.year, 12, 31);
    if (today.isAfter(endOfYear)) return 0;
    return endOfYear.difference(today).inDays + 1;
  }
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
    required this.isTopBadge,
    required this.isAttainableThisYear,
  });

  factory NextBadgeProgress.topBadge({
    required EfsBadge currentBadge,
    required double currentScore,
  }) {
    return NextBadgeProgress(
      currentBadge: currentBadge,
      nextBadge: null,
      currentScore: currentScore,
      targetScore: currentBadge.maximumScore,
      progress: 1.0,
      xpGap: 0,
      daysRemaining: 0,
      averageDailyXp: 0,
      isTopBadge: true,
      isAttainableThisYear: true,
    );
  }
}
