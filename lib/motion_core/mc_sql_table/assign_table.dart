import 'package:motion/motion_core/mc_sqlite/database_constants.dart';

// Structure of the 'to_assign' database table
class Assigner {
  late int id; // Unique identifier for the assignment
  final String currentLoggedInUser; // User who created the assignment
  final String subcategoryName; // Subcategory of the assignment
  final String mainCategoryName; // Main category of the assignment
  late int
      isActive; // Indicates whether the assignment is active (0 == false, 1 == true)
  late int
      isArchive; // Indicates whether the assignment is archived (0 == false, 1 == true)
  final String dateCreated; // Date when the assignment was created
  final int isStreakActive;
  final String streakType;
  final double streakTargetMinutes;
  final String streakStartDate;

  Assigner({
    this.id = 0, // Assignment ID (auto-generated in the database)
    required this.currentLoggedInUser,
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.dateCreated,
    this.isActive = 0,
    this.isArchive = 0,
    this.isStreakActive = 0,
    this.streakType = "",
    this.streakTargetMinutes = 0.0,
    this.streakStartDate = "",
  });

  // Factory constructor to create an 'Assigner' object
  // from a map of database columns
  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
      id: map[MotionDbColumns.id] ?? 0, // Extract ID from the map
      currentLoggedInUser:
          map[MotionDbColumns.currentLoggedInUser] ?? "", // Extract user
      subcategoryName:
          map[MotionDbColumns.subcategoryName] ?? "", // Extract subcategory
      mainCategoryName:
          map[MotionDbColumns.mainCategoryName] ?? "", // Extract main category
      isActive: map[MotionDbColumns.isActive] ?? 0, // Extract isActive (0 or 1)
      isArchive:
          map[MotionDbColumns.isArchive] ?? 0, // Extract isArchive (0 or 1)
      dateCreated:
          map[MotionDbColumns.dateCreated] ?? "", // Extract creation date
      isStreakActive: map[MotionDbColumns.isStreakActive] ?? 0,
      streakType: map[MotionDbColumns.streakType] ?? "",
      streakTargetMinutes:
          (map[MotionDbColumns.streakTargetMinutes] as num?)?.toDouble() ??
              0.0,
      streakStartDate: map[MotionDbColumns.streakStartDate] ?? "",
    );
  }

  // Convert 'Assigner' object to a map for database insertion
  Map<String, dynamic> toMap() {
    return {
      MotionDbColumns.currentLoggedInUser: currentLoggedInUser,
      MotionDbColumns.subcategoryName: subcategoryName,
      MotionDbColumns.mainCategoryName: mainCategoryName,
      MotionDbColumns.isActive: isActive,
      MotionDbColumns.isArchive: isArchive, // Include isArchive in the map
      MotionDbColumns.dateCreated: dateCreated,
      MotionDbColumns.isStreakActive: isStreakActive,
      MotionDbColumns.streakType: streakType,
      MotionDbColumns.streakTargetMinutes: streakTargetMinutes,
      MotionDbColumns.streakStartDate: streakStartDate,
    };
  }

  @override
  String toString() {
    return 'Assigner{id: $id, currentLoggedInUser: $currentLoggedInUser, subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName, isActive: $isActive, isArchive: $isArchive, dateCreated: $dateCreated, isStreakActive: $isStreakActive, streakType: $streakType, streakTargetMinutes: $streakTargetMinutes, streakStartDate: $streakStartDate}';
  }
}
