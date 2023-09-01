import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/main_and_sub.dart';

// database instance
final AssignerDatabaseHelper dbInstance = AssignerDatabaseHelper();

class AssignerMainProvider extends ChangeNotifier {
  List<Assigner> _assignerItems = [];

  List<Assigner> get assignerItems => _assignerItems;

  // get all items in the assigner.db database
  Future<void> getAllUserItems() async {
    _assignerItems = await dbInstance.getAllItems();

    notifyListeners();
  }

  // insert items into the assigner.db database
  Future<void> insertIntoAssignerDb(Assigner categoryAssigner) async {
    await dbInstance.assignInsert(categoryAssigner);

    notifyListeners();
  }

  // update existing items in the assigner.db database
  Future<void> updateAssignedItems(Assigner categoryAssigner) async {
    await dbInstance.assignUpdate(categoryAssigner);
    await getAllUserItems();

    notifyListeners();
  }
}

// this provider gets all the subcategories that are active
class ActiveAssignedProvider extends ChangeNotifier {
  List<Assigner> _activeSubcategories = [];

  List<Assigner> get activeSubcategories => _activeSubcategories;

  Future<void> activeSubcategoriesList() async {
    _activeSubcategories = await dbInstance.getAllActiveItems();

    notifyListeners();
  }
}
