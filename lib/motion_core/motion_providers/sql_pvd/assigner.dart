import 'package:flutter/material.dart';
import 'package:motion/motion_core/mc_sqlite/main_and_sub.dart';

class AssignerProvider extends ChangeNotifier {
  List<Assigner> _assignedItems = [];

  List<Assigner> get assignedItems => _assignedItems;

  AssignerProvider() {
    getAssignedSubcategories();
  }

  Future<void> getAssignedSubcategories() async {
    _assignedItems = await AssignerDatabaseHelper.getAllItems();

    notifyListeners();
  }
}