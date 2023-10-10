// Structure of the 'subcategories' table
class Subcategories {
  int? id; // Unique identifier for the subcategory
  final String date; // Date associated with the record
  final String mainCategoryName; // Name of the main category
  final String subcategoryName; // Name of the subcategory
  final String timeRecorded; // Timestamp of when the time was recorded
  double timeSpent; // Amount of time spent in the subcategory
  final String currentLoggedInUser; // User associated with the record


  Subcategories({
    this.id,
    required this.date,
    required this.mainCategoryName,
    required this.subcategoryName,
    required this.timeRecorded,
    this.timeSpent = 0.0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to Subcategories object
  factory Subcategories.fromMap(Map<String, dynamic> map) {
    return Subcategories(
      id: map["id"],
      date: map['date'],
      mainCategoryName: map['mainCategoryName'],
      subcategoryName: map['subcategoryName'],
      timeRecorded: map["timeRecorded"],
      timeSpent: map['timeSpent'],
      currentLoggedInUser: map['currentLoggedInUser'],
    );
  }

  // Convert Subcategories object to a map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'mainCategoryName': mainCategoryName,
      'subcategoryName': subcategoryName,
      'timeRecorded': timeRecorded,
      'timeSpent': timeSpent,
      'currentLoggedInUser': currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Subcategories {'
        'Id: $id, '
        'date: $date, '
        'mainCategoryName: $mainCategoryName, '
        'subcategoryName $subcategoryName, '
        'timeRecorded: $timeRecorded,'
        'timeSpent: $timeSpent, '
        'currentLoggedInUser: $currentLoggedInUser'
        '}';
  }
}
