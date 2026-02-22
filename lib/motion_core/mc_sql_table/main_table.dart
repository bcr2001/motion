// Structure of the 'main_category' table
class MainCategory {
  final String date; // Date associated with the record
  double education; // Amount of time spent on education
  double skills; // Amount of time spent on skills development
  double entertainment; // Amount of time spent on entertainment
  double selfDevelopment; // Amount of time spent on Self Development
  double sleep; // Amount of time spent on sleep
  String currentLoggedInUser; // User associated with the record

  MainCategory({
    required this.date,
    this.education = 0.0, // Default value for education
    this.skills = 0.0, // Default value for skills
    this.entertainment = 0.0, // Default value for entertainment
    this.selfDevelopment = 0.0, // Default value for Self Development
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
      selfDevelopment: map['selfDevelopment'] ?? 0.0,
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
      'selfDevelopment': selfDevelopment,
      'sleep': sleep,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Main category{date: $date, education: $education, skills: $skills, entertainment: $entertainment, selfDevelopment: $selfDevelopment, sleep: $sleep, user: $currentLoggedInUser}';
  }
}
