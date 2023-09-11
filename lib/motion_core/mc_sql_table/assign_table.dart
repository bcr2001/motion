class Assigner {
  int? id;
  final String currentLoggedInUser;
  final String subcategoryName;
  final String mainCategoryName;
  int isActive;
  final String dateCreated;

  Assigner({
    this.id,
    required this.currentLoggedInUser,
    required this.subcategoryName,
    required this.mainCategoryName,
    required this.dateCreated,
    this.isActive = 0,
  });
  // (0 == false while 1 == true)

  factory Assigner.fromAssignerMap(Map<String, dynamic> map) {
    return Assigner(
        id: map["id"],
        currentLoggedInUser: map["currentLoggedInUser"],
        subcategoryName: map["subcategoryName"],
        mainCategoryName: map["mainCategoryName"],
        isActive: map["isActive"],
        dateCreated: map["dateCreated"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "currentLoggedInUser": currentLoggedInUser,
      "subcategoryName": subcategoryName,
      "mainCategoryName": mainCategoryName,
      "isActive": isActive,
      "dateCreated": dateCreated
    };
  }

  @override
  String toString() {
    return 'CategoryAssigner{id: $id,currentLoggedInUser: $currentLoggedInUser ,subcategoryName: $subcategoryName, mainCategoryName: $mainCategoryName, isActive: $isActive,dateCreated: $dateCreated}';
  }
}
