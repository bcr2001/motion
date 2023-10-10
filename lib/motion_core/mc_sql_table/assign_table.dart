// Structure of the 'to_assign' database table
class Assigner {
  int? id; // Unique identifier for the assignment
  final String currentLoggedInUser; // User who created the assignment
  final String subcategoryName; // Subcategory of the assignment
  final String mainCategoryName; // Main category of the assignment
  int isActive; // Indicates whether the assignment is active (0 == false, 1 == true)
  int isArchive; // Indicates whether the assignment is archived (0 == false, 1 == true)
  final String dateCreated; // Date when the assignment was created

  Assigner({
    this.id, // Assignment ID (auto-generated in the database)
    required this.currentLoggedInUser,
    required this.subcategoryName, 
    required this.mainCategoryName, 
    required this.dateCreated, 
    this.isActive = 0, 
    this.isArchive =
        0,
  });

  // Factory constructor to create an 'Assigner' object from a map of database columns
  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
      id: map["id"], // Extract ID from the map
      currentLoggedInUser: map["currentLoggedInUser"], // Extract user
      subcategoryName: map["subcategoryName"], // Extract subcategory
      mainCategoryName: map["mainCategoryName"], // Extract main category
      isActive: map["isActive"], // Extract isActive (0 or 1)
      isArchive: map["isArchive"], // Extract isArchive (0 or 1)
      dateCreated: map["dateCreated"], // Extract creation date
    );
  }

  // Convert 'Assigner' object to a map for database insertion
  Map<String, dynamic> toMap() {
    return {
      "currentLoggedInUser": currentLoggedInUser,
      "subcategoryName": subcategoryName,
      "mainCategoryName": mainCategoryName,
      "isActive": isActive,
      "isArchive": isArchive, // Include isArchive in the map
      "dateCreated": dateCreated,
    };
  }

  @override
  String toString() {
    return 'Assigner{id: $id, currentLoggedInUser: $currentLoggedInUser, subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName, isActive: $isActive, isArchive: $isArchive, dateCreated: $dateCreated}';
  }
}
