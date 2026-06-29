import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_core/mc_sql_table/assign_table.dart';
import 'package:motion/motion_core/motion_providers/sql_pvd/assigner_pvd.dart';

void main() {
  test('assigner items cannot be mutated outside the provider', () {
    final provider = AssignerMainProvider();

    expect(
      () => provider.assignerItems.add(
        Assigner(
          currentLoggedInUser: 'user-1',
          subcategoryName: 'Chess',
          mainCategoryName: 'Skills',
          dateCreated: '2026-06-23',
        ),
      ),
      throwsUnsupportedError,
    );
  });
}
