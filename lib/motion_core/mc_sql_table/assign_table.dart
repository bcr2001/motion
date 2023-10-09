// structure of the to_assign database table
class Assigner {
  int? id;
  final String currentLoggedInUser;
  final String subcategoryName;
  final String mainCategoryName;
  int isActive;
  int isArchive; // New property for isArchive
  final String dateCreated;

  Assigner({
    this.id,
    required this.currentLoggedInUser,
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.dateCreated,
    this.isActive = 0,
    this.isArchive = 0, // Initialize isArchive with a default value
  });
  // (0 == false while 1 == true)

  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
        id: map["id"],
        currentLoggedInUser: map["currentLoggedInUser"],
        subcategoryName: map["subcategoryName"],
        mainCategoryName: map["mainCategoryName"],
        isActive: map["isActive"],
        isArchive: map["isArchive"], // Read isArchive from the map
        dateCreated: map["dateCreated"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "currentLoggedInUser": currentLoggedInUser,
      "subcategoryName": subcategoryName,
      "mainCategoryName": mainCategoryName,
      "isActive": isActive,
      "isArchive": isArchive, // Include isArchive in the map
      "dateCreated": dateCreated
    };
  }

  @override
  String toString() {
    return 'Assigner{id: $id, currentLoggedInUser: $currentLoggedInUser, subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName, isActive: $isActive, isArchive: $isArchive, dateCreated: $dateCreated}';
  }
}
