import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

// Structure of the 'main_category' table
class MainCategory {
  final String date; // Date associated with the record
  double education; // Amount of time spent on education
  double work; // Amount of time spent on work
  double skills; // Amount of time spent on skills development
  double entertainment; // Amount of time spent on entertainment
  double selfDevelopment; // Amount of time spent on Self Development
  double sleep; // Amount of time spent on sleep
  String currentLoggedInUser; // User associated with the record

  MainCategory({
    required this.date,
    this.education = 0.0, // Default value for education
    this.work = 0.0, // Default value for work
    this.skills = 0.0, // Default value for skills
    this.entertainment = 0.0, // Default value for entertainment
    this.selfDevelopment = 0.0, // Default value for Self Development
    this.sleep = 0.0, // Default value for sleep
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to MainCategory object
  factory MainCategory.fromMap(Map<String, dynamic> map) {
    return MainCategory(
      date: map[MotionDbColumns.date],
      education: map[MotionDbColumns.education] ?? 0.0,
      work: map[MotionDbColumns.work] ?? 0.0,
      skills: map[MotionDbColumns.skills] ?? 0.0,
      entertainment: map[MotionDbColumns.entertainment] ?? 0.0,
      selfDevelopment: map[MotionDbColumns.selfDevelopment] ?? 0.0,
      sleep: map[MotionDbColumns.sleep] ?? 0.0,
      currentLoggedInUser: map[MotionDbColumns.currentLoggedInUser],
    );
  }

  // Convert MainCategory object to a map
  Map<String, dynamic> toMap() {
    return {
      MotionDbColumns.date: date,
      MotionDbColumns.education: education,
      MotionDbColumns.work: work,
      MotionDbColumns.skills: skills,
      MotionDbColumns.entertainment: entertainment,
      MotionDbColumns.selfDevelopment: selfDevelopment,
      MotionDbColumns.sleep: sleep,
      MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Main category{date: $date, education: $education, work: $work, skills: $skills, entertainment: $entertainment, selfDevelopment: $selfDevelopment, sleep: $sleep, user: $currentLoggedInUser}';
  }
}
