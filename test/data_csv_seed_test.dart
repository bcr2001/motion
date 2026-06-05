import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('data_csv seeds', () {
    test('includes AI-Assisted Development as a Skills assignment', () {
      final toAssignCsv =
          File('assets/data_csv/to_assign.csv').readAsStringSync();

      expect(
        toAssignCsv,
        contains(
          'hhANBj74wiclvfuDLGfuDlFZgJ62,AI-Assisted Development,Skills,0,0,6/4/2026',
        ),
      );
    });

    test('tracks AI-Assisted Development under Skills on 6/4/2026', () {
      final subcategoryCsv =
          File('assets/data_csv/subcategory.csv').readAsStringSync();

      expect(
        subcategoryCsv,
        contains(
          '6/4/2026,Skills,AI-Assisted Development,208.15,hhANBj74wiclvfuDLGfuDlFZgJ62',
        ),
      );
    });
  });
}
