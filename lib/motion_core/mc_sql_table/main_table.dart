// Structure of the 'main_category' table
class MainCategory {
  final String date; // Date associated with the record
  double education; // Amount of time spent on education
  double skills; // Amount of time spent on skills development
  double entertainment; // Amount of time spent on entertainment
  double personalGrowth; // Amount of time spent on personal growth
  double sleep; // Amount of time spent on sleep
  String currentLoggedInUser; // User associated with the record

  MainCategory({
    required this.date,
    this.education = 0.0, // Default value for education
    this.skills = 0.0, // Default value for skills
    this.entertainment = 0.0, // Default value for entertainment
    this.personalGrowth = 0.0, // Default value for personal growth
    this.sleep = 0.0, // Default value for sleep
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to MainCategory object
  factory MainCategory.fromMap(Map<String, dynamic> map) {
    return MainCategory(
      date: map['date'],
      education: map['education'] ?? 0.0,
      skills: map['skills'] ?? 0.0,
      entertainment: map['entertainment'] ?? 0.0,
      personalGrowth: map['personalGrowth'] ?? 0.0,
      sleep: map['sleep'] ?? 0.0,
      currentLoggedInUser: map['currentLoggedInUser'],
    );
  }

  // Convert MainCategory object to a map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'education': education,
      'skills': skills,
      'entertainment': entertainment,
      'personalGrowth': personalGrowth,
      'sleep': sleep,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Main category{date: $date, education: $education, skills: $skills, entertainment: $entertainment, personalGrowth: $personalGrowth, sleep: $sleep, user: $currentLoggedInUser}';
  }
}
