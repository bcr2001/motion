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
}
