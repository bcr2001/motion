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
      assetPath: 'assets/images/motion_badges/dear_award.png',
      lockedAssetPath: 'assets/images/motion_badges/dear_award_grey.png',
    ),
    MotionAward(
      name: 'Fox',
      requiredHours: 50,
      assetPath: 'assets/images/motion_badges/fox_award.png',
      lockedAssetPath: 'assets/images/motion_badges/fox_award_grey.png',
    ),
    MotionAward(
      name: 'Wolf',
      requiredHours: 100,
      assetPath: 'assets/images/motion_badges/wolf_award.png',
      lockedAssetPath: 'assets/images/motion_badges/wolf_award_grey.png',
    ),
    MotionAward(
      name: 'Horse',
      requiredHours: 250,
      assetPath: 'assets/images/motion_badges/horse_award.png',
      lockedAssetPath: 'assets/images/motion_badges/horse_award_grey.png',
    ),
    MotionAward(
      name: 'Bear',
      requiredHours: 500,
      assetPath: 'assets/images/motion_badges/bear_award.png',
      lockedAssetPath: 'assets/images/motion_badges/bear_award_grey.png',
    ),
    MotionAward(
      name: 'Eagle',
      requiredHours: 1000,
      assetPath: 'assets/images/motion_badges/eagle_award.png',
      lockedAssetPath: 'assets/images/motion_badges/eagle_award_grey.png',
    ),
    MotionAward(
      name: 'Elephant',
      requiredHours: 2500,
      assetPath: 'assets/images/motion_badges/elephant_award.png',
      lockedAssetPath: 'assets/images/motion_badges/elephant_award_grey.png',
    ),
    MotionAward(
      name: 'Tiger',
      requiredHours: 5000,
      assetPath: 'assets/images/motion_badges/tiger_award.png',
      lockedAssetPath: 'assets/images/motion_badges/tiger_award_grey.png',
    ),
    MotionAward(
      name: 'Crocodile',
      requiredHours: 8760,
      assetPath: 'assets/images/motion_badges/crocodile_award.png',
      lockedAssetPath:
          'assets/images/motion_badges/crocodile_award_grey.png',
    ),
    MotionAward(
      name: 'Rhino',
      requiredHours: 10000,
      assetPath: 'assets/images/motion_badges/rhino_award.png',
      lockedAssetPath: 'assets/images/motion_badges/rhino_award_grey.png',
    ),
    MotionAward(
      name: 'Lion',
      requiredHours: 25000,
      assetPath: 'assets/images/motion_badges/lion_award.png',
      lockedAssetPath: 'assets/images/motion_badges/lion_award_grey.png',
    ),
    MotionAward(
      name: 'Dragon',
      requiredHours: 50000,
      assetPath: 'assets/images/motion_badges/dragon_award.png',
      lockedAssetPath: 'assets/images/motion_badges/dragon_award_grey.png',
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
