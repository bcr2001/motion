import 'package:flutter_test/flutter_test.dart';
import 'package:motion/motion_routes/mr_home/home_windows/subcategory_rank_movement.dart';

void main() {
  test('reports the exact number of positions moved in the comparison period',
      () {
    final ranked = applySubcategoryRankMovement(
      rankedItems: [
        {'subcategoryName': 'Alpha', 'total': 100.0},
        {'subcategoryName': 'Bravo', 'total': 120.0},
        {'subcategoryName': 'Charlie', 'total': 90.0},
      ],
      comparisonPeriodTotals: const {'Bravo': 50.0},
    );

    expect(ranked.map((item) => item['subcategoryName']), [
      'Bravo',
      'Alpha',
      'Charlie',
    ]);
    expect(ranked[0]['rankMovement'], 2);
    expect(ranked[1]['rankMovement'], -1);
    expect(ranked[2]['rankMovement'], -1);
  });

  test('marks a first period entry as new and moves overtaken entries down',
      () {
    final ranked = applySubcategoryRankMovement(
      rankedItems: [
        {'subcategoryName': 'Existing', 'total': 100.0},
        {'subcategoryName': 'New Entry', 'total': 110.0},
      ],
      comparisonPeriodTotals: const {'New Entry': 110.0},
    );

    expect(ranked[0]['subcategoryName'], 'New Entry');
    expect(ranked[0]['isNewRank'], isTrue);
    expect(ranked[0]['rankMovement'], 0);
    expect(ranked[1]['subcategoryName'], 'Existing');
    expect(ranked[1]['rankMovement'], -1);
  });

  test('does not show an upward move until a subcategory actually overtakes',
      () {
    final ranked = applySubcategoryRankMovement(
      rankedItems: [
        {'subcategoryName': 'Leader', 'total': 100.0},
        {'subcategoryName': 'Challenger', 'total': 100.0},
      ],
      comparisonPeriodTotals: const {'Challenger': 10.0},
    );

    expect(ranked[0]['subcategoryName'], 'Leader');
    expect(ranked[1]['subcategoryName'], 'Challenger');
    expect(ranked[0]['rankMovement'], 0);
    expect(ranked[1]['rankMovement'], 0);
  });

  test('does not mutate the query result maps', () {
    final original = [
      {'subcategoryName': 'Alpha', 'total': 10.0},
    ];

    applySubcategoryRankMovement(
      rankedItems: original,
      comparisonPeriodTotals: const {},
    );

    expect(original.single.containsKey('rankMovement'), isFalse);
  });
}
