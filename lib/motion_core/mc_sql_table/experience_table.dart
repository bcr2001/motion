/// Represents experience points for different categories on a specific date.
class ExperiencePoints {
  final String date;
  int educationXP;
  int skillsXP;
  int sdXP;
  int sleepXP;
  String currentLoggedInUser;

  ExperiencePoints(
      {required this.date,
      this.educationXP = 0,
      this.skillsXP = 0,
      this.sdXP = 0,
      this.sleepXP = 0,
      required this.currentLoggedInUser});

  // Factory constructor to convert a map to MainCategory object
  factory ExperiencePoints.fromMap(Map<String, dynamic> map) {
    return ExperiencePoints(
        date: map["date"],
        educationXP: map["educationXP"] ?? 0,
        skillsXP: map["skillsXP"] ?? 0,
        sdXP: map["sdXP"] ?? 0,
        sleepXP: map["sleepXP"] ?? 0,
        currentLoggedInUser: map["currentLoggedInUser"]);
  }

  // Convert MainCategory object to a map
  Map<String, dynamic> toMap() {
    return {
      "date": date,
      "educationXP": educationXP,
      "skillsXP": skillsXP,
      "sdXP": sdXP,
      "sleepXP": sleepXP,
      "currentLoggedInUser": currentLoggedInUser
    };
  }

  @override
  String toString() {
    return 'Experience Points{date: $date, educationXP": $educationXP, skillsXP: $skillsXP, sdXP: $sdXP, sleepXP: $sleepXP, currentLoggedInUser: $currentLoggedInUser}';
  }
}
