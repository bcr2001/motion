import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

// Structure of the 'subcategories' table
class Subcategories {
  int? id; // Unique identifier for the subcategory
  final String date; // Date associated with the record
  final String mainCategoryName; // Name of the main category
  final String subcategoryName; // Name of the subcategory
  double timeSpent; // Amount of time spent in the subcategory
  final String currentLoggedInUser; // User associated with the record

  Subcategories({
    this.id,
    required this.date,
    required this.mainCategoryName,
    required this.subcategoryName,
    this.timeSpent = 0.0,
    required this.currentLoggedInUser,
  });

  // Factory constructor to convert a map to Subcategories object
  factory Subcategories.fromMap(Map<String, dynamic> map) {
    return Subcategories(
      id: map[MotionDbColumns.id],
      date: map[MotionDbColumns.date],
      mainCategoryName: map[MotionDbColumns.mainCategoryName],
      subcategoryName: map[MotionDbColumns.subcategoryName],
      timeSpent: map[MotionDbColumns.timeSpent],
      currentLoggedInUser: map[MotionDbColumns.currentLoggedInUser],
    );
  }

  // Convert Subcategories object to a map
  Map<String, dynamic> toMap() {
    return {
      MotionDbColumns.date: date,
      MotionDbColumns.mainCategoryName: mainCategoryName,
      MotionDbColumns.subcategoryName: subcategoryName,
      MotionDbColumns.timeSpent: timeSpent,
      MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
    };
  }

  @override
  String toString() {
    return 'Subcategories {'
        'Id: $id, '
        'date: $date, '
        'mainCategoryName: $mainCategoryName, '
        'subcategoryName $subcategoryName, '
        'timeSpent: $timeSpent, '
        'currentLoggedInUser: $currentLoggedInUser'
        '}';
  }
}
