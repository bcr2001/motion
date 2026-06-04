import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/mc_sql_table/experience_table.dart';
import 'package:motion/motion_core/mc_sql_table/main_table.dart';
import 'package:motion/motion_core/mc_sql_table/sub_table.dart';

String requireCurrentUser(String currentUser) {
  final trimmedUser = currentUser.trim();

  if (trimmedUser.isEmpty) {
    throw ArgumentError.value(
      currentUser,
      'currentUser',
      'A current user UID is required.',
    );
  }

  return trimmedUser;
}

MainCategory requireMainCategoryUser(MainCategory mainCategory) {
  requireCurrentUser(mainCategory.currentLoggedInUser);
  return mainCategory;
}

Subcategories requireSubcategoryUser(Subcategories subcategories) {
  requireCurrentUser(subcategories.currentLoggedInUser);
  return subcategories;
}

ExperiencePoints requireExperienceUser(ExperiencePoints experience) {
  requireCurrentUser(experience.currentLoggedInUser);
  return experience;
}

Assigner requireAssignerUser(Assigner assigner) {
  requireCurrentUser(assigner.currentLoggedInUser);
  return assigner;
}
