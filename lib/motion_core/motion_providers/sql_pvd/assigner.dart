import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/main_and_sub.dart';

class AssignerProvider extends ChangeNotifier {
  AssignerDatabaseHelper dbInstance = AssignerDatabaseHelper();

  List<Assigner> _assignedItems = [];

  List<Assigner> get assignedItems => _assignedItems;

  AssignerProvider() {
    getAssignedSubcategories();
  }

  // get all subcategories form the to_assign table
  Future<void> getAssignedSubcategories() async {
    _assignedItems = await dbInstance.getAllItems();

    notifyListeners();
  }

  // insert data into the to_assign table
  Future<void> insertIntoAssign(Assigner categoryAssigner) async {
    await dbInstance.assignInsert(categoryAssigner);

    notifyListeners();
  }

  
}
