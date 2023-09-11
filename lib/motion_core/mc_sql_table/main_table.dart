class MainCategory {
  final String date;
  double education;
  double skills;
  double entertainment;
  double personalGrowth;
  double sleep;
  String currentLoggedInUser;

  MainCategory({
    required this.date,
    this.education = 0.0,
    this.skills = 0.0,
    this.entertainment = 0.0,
    this.personalGrowth = 0.0,
    this.sleep = 0.0,
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
