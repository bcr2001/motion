import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sqlite/sql_assigner_db.dart';

// database instance
final AssignerDatabaseHelper dbInstance = AssignerDatabaseHelper();

// handles the database operations for the to_assign table
class AssignerMainProvider extends ChangeNotifier {
  // a list of subcategories and all it's relevant information
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
    await getAllUserItems();

    notifyListeners();
  }

  // update existing items in the to_assign table
  Future<void> updateAssignedItems(Assigner categoryAssigner) async {
    await dbInstance.assignUpdate(categoryAssigner);
    await getAllUserItems();

    notifyListeners();
  }

  // delete existing items in the to_assign table
  Future<void> deleteAssignedItems(int id) async {
    await dbInstance.assignDelete(id);
    await getAllUserItems();
    
    notifyListeners();
  }
}
