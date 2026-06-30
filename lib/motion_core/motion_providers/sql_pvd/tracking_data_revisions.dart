import 'package:flutter/foundation.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';

class TrackingDataRevisions extends ChangeNotifier {
  int _subcategoryRevision = 0;
  int _mainCategoryRevision = 0;
  int _experiencePointRevision = 0;
  final Map<String, int> _subcategoryRevisions = {};
  final Map<String, int> _dateRevisions = {};

  int get subcategoryRevision => _subcategoryRevision;
  int get mainCategoryRevision => _mainCategoryRevision;
  int get experiencePointRevision => _experiencePointRevision;

  int revisionForSubcategory({
    required String currentUser,
    required String mainCategoryName,
    required String subcategoryName,
  }) {
    return _subcategoryRevisions[
            _subcategoryKey(
              currentUser: currentUser,
              mainCategoryName: mainCategoryName,
              subcategoryName: subcategoryName,
            )] ??
        0;
  }

  int revisionForDate({
    required String currentUser,
    required String date,
  }) {
    return _dateRevisions[_dateKey(currentUser: currentUser, date: date)] ?? 0;
  }

  void markSubcategoryChanged(Subcategories subcategory) {
    _subcategoryRevision++;
    _mainCategoryRevision++;
    _experiencePointRevision++;

    final key = _subcategoryKey(
      currentUser: subcategory.currentLoggedInUser,
      mainCategoryName: subcategory.mainCategoryName,
      subcategoryName: subcategory.subcategoryName,
    );
    _subcategoryRevisions[key] = (_subcategoryRevisions[key] ?? 0) + 1;

    final dateKey = _dateKey(
      currentUser: subcategory.currentLoggedInUser,
      date: subcategory.date,
    );
    _dateRevisions[dateKey] = (_dateRevisions[dateKey] ?? 0) + 1;
    notifyListeners();
  }

  void markMainCategoryChanged() {
    _mainCategoryRevision++;
    _experiencePointRevision++;
    notifyListeners();
  }

  void markExperiencePointsChanged() {
    _experiencePointRevision++;
    notifyListeners();
  }

  void markAllTrackingDataChanged() {
    _subcategoryRevision++;
    _mainCategoryRevision++;
    _experiencePointRevision++;
    notifyListeners();
  }

  String _subcategoryKey({
    required String currentUser,
    required String mainCategoryName,
    required String subcategoryName,
  }) {
    return '$currentUser|$mainCategoryName|$subcategoryName';
  }

  String _dateKey({
    required String currentUser,
    required String date,
  }) {
    return '$currentUser|$date';
  }
}
