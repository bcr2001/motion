class MotionAward {
  final String name;
  final int requiredHours;
  final String assetPath;
  final String lockedAssetPath;

  const MotionAward({
    required this.name,
    required this.requiredHours,
    required this.assetPath,
    required this.lockedAssetPath,
  });

  int get requiredMinutes => requiredHours * 60;
}

class MotionAwards {
  static const List<MotionAward> all = [
    MotionAward(
      name: 'Deer',
      requiredHours: 24,
      assetPath: 'assets/images/motion_badges/24_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/24_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Wolf',
      requiredHours: 100,
      assetPath: 'assets/images/motion_badges/100_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/100_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Horse',
      requiredHours: 250,
      assetPath: 'assets/images/motion_badges/250_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/250_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Bear',
      requiredHours: 500,
      assetPath: 'assets/images/motion_badges/500_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/500_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Eagle',
      requiredHours: 1000,
      assetPath: 'assets/images/motion_badges/1000_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/1000_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Elephant',
      requiredHours: 2500,
      assetPath: 'assets/images/motion_badges/2500_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/2500_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Tiger',
      requiredHours: 5000,
      assetPath: 'assets/images/motion_badges/5000_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/5000_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Crocodile',
      requiredHours: 8760,
      assetPath: 'assets/images/motion_badges/8760_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/8760_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Rhino',
      requiredHours: 10000,
      assetPath: 'assets/images/motion_badges/10000_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/10000_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Lion',
      requiredHours: 25000,
      assetPath: 'assets/images/motion_badges/25000_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/25000_hour_award_grey.png',
    ),
    MotionAward(
      name: 'Dragon',
      requiredHours: 50000,
      assetPath: 'assets/images/motion_badges/50000_hour_award.png',
      lockedAssetPath: 'assets/images/motion_badges/50000_hour_award_grey.png',
    ),
  ];

  static MotionAward? earnedAt(double trackedHours) {
    MotionAward? earned;
    for (final award in all) {
      if (trackedHours < award.requiredHours) break;
      earned = award;
    }
    return earned;
  }

  static MotionAward? nextAfter(double trackedHours) {
    for (final award in all) {
      if (trackedHours < award.requiredHours) return award;
    }
    return null;
  }
}
