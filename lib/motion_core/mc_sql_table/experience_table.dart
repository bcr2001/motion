import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

/// Represents experience points for different categories on a specific date.
class ExperiencePoints {
  final String date;
  int educationXP;
  int workXP;
  int skillsXP;
  int sdXP;
  int sleepXP;
  int accountabilityBonusXP;
  String currentLoggedInUser;

  ExperiencePoints(
      {required this.date,
      this.educationXP = 0,
      this.workXP = 0,
      this.skillsXP = 0,
      this.sdXP = 0,
      this.sleepXP = 0,
      this.accountabilityBonusXP = 0,
      required this.currentLoggedInUser});

  // Factory constructor to convert a map to MainCategory object
  factory ExperiencePoints.fromMap(Map<String, dynamic> map) {
    return ExperiencePoints(
        date: map[MotionDbColumns.date],
        educationXP: map[MotionDbColumns.educationXp] ?? 0,
        workXP: map[MotionDbColumns.workXp] ?? 0,
        skillsXP: map[MotionDbColumns.skillsXp] ?? 0,
        sdXP: map[MotionDbColumns.selfDevelopmentXp] ?? 0,
        sleepXP: map[MotionDbColumns.sleepXp] ?? 0,
        accountabilityBonusXP:
            map[MotionDbColumns.accountabilityBonusXp] ?? 0,
        currentLoggedInUser: map[MotionDbColumns.currentLoggedInUser]);
  }

  // Convert MainCategory object to a map
  Map<String, dynamic> toMap() {
    return {
      MotionDbColumns.date: date,
      MotionDbColumns.educationXp: educationXP,
      MotionDbColumns.workXp: workXP,
      MotionDbColumns.skillsXp: skillsXP,
      MotionDbColumns.selfDevelopmentXp: sdXP,
      MotionDbColumns.sleepXp: sleepXP,
      MotionDbColumns.accountabilityBonusXp: accountabilityBonusXP,
      MotionDbColumns.currentLoggedInUser: currentLoggedInUser
    };
  }

  @override
  String toString() {
    return 'Experience Points{date: $date, educationXP": $educationXP, workXP: $workXP, skillsXP: $skillsXP, sdXP: $sdXP, sleepXP: $sleepXP, accountabilityBonusXP: $accountabilityBonusXP, currentLoggedInUser: $currentLoggedInUser}';
  }
}
